#!/usr/bin/env python3
"""
F1 Race Results Scheduler
Spawns one-time cron jobs to fetch results after each race starts.
"""

import os
import sys
import sqlite3
import json
from datetime import datetime, timedelta
import logging
import subprocess

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE_PATH = os.environ.get('DATABASE_PATH', '/data/f1_predictions.db')
STATE_FILE = '/tmp/f1_scheduler_state.json'

def get_db():
    """Get database connection."""
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def load_state():
    """Load scheduler state."""
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    return {'scheduled_jobs': []}

def save_state(state):
    """Save scheduler state."""
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def get_upcoming_races():
    """Get races that haven't been scheduled yet."""
    db = get_db()
    try:
        races = db.execute('''
            SELECT id, name, round, date, status
            FROM races
            WHERE status IN ('open', 'upcoming', 'locked')
            ORDER BY date ASC
        ''').fetchall()
        return [dict(race) for race in races]
    finally:
        db.close()

def schedule_race_result_job(race_id, race_name, race_datetime):
    """
    Schedule a one-time job to fetch results 1.5 hours after race starts.
    Uses 'at' command for one-time scheduling.
    """
    # Calculate when to run: race start + 1.5 hours
    race_time = datetime.strptime(race_datetime, '%Y-%m-%d %H:%M:%S')
    fetch_time = race_time + timedelta(hours=1, minutes=30)
    
    # Format for 'at' command
    at_time = fetch_time.strftime('%H:%M %Y-%m-%d')
    
    # Build the command to run
    script_path = os.path.join(os.path.dirname(__file__), 'fetch_race_results.py')
    command = f'cd {os.path.dirname(__file__)} && python3 {script_path}'
    
    # Schedule with 'at'
    try:
        # Check if 'at' is available
        result = subprocess.run(['which', 'at'], capture_output=True, text=True)
        if result.returncode != 0:
            logger.error("'at' command not available")
            return False
        
        # Create the at job
        at_command = f'echo "{command}" | at {at_time} 2>&1'
        result = subprocess.run(at_command, shell=True, capture_output=True, text=True)
        
        if result.returncode == 0:
            job_id = result.stdout.strip()
            logger.info(f"✅ Scheduled job for {race_name} at {at_time} (job: {job_id})")
            return True
        else:
            logger.error(f"Failed to schedule: {result.stderr}")
            return False
            
    except Exception as e:
        logger.error(f"Error scheduling job: {e}")
        return False

def spawn_kubernetes_cronjob(race_id, race_name, race_datetime):
    """
    Alternative: Spawn a Kubernetes CronJob that runs once.
    This is more reliable for production.
    """
    race_time = datetime.strptime(race_datetime, '%Y-%m-%d %H:%M:%S')
    fetch_time = race_time + timedelta(hours=1, minutes=30)
    
    # Format for CronJob schedule (minute hour day month day-of-week)
    schedule = f"{fetch_time.minute} {fetch_time.hour} {fetch_time.day} {fetch_time.month} *"
    
    job_name = f"f1-fetch-results-r{race_id}-{fetch_time.strftime('%m%d')}"
    
    cronjob_yaml = f'''apiVersion: batch/v1
kind: CronJob
metadata:
  name: {job_name}
  namespace: f1-predictor
spec:
  schedule: "{schedule}"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 3600
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: fetch-results
            image: python:3.11-slim
            command:
            - /bin/sh
            - -c
            - |
              pip install requests -q && 
              python3 /app/cron/fetch_race_results.py
            volumeMounts:
            - name: app-code
              mountPath: /app
            - name: data
              mountPath: /data
          volumes:
          - name: app-code
            persistentVolumeClaim:
              claimName: f1-predictor-data
          - name: data
            persistentVolumeClaim:
              claimName: f1-predictor-data
'''
    
    # Write to temp file and apply
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as f:
        f.write(cronjob_yaml)
        temp_file = f.name
    
    try:
        result = subprocess.run(
            ['kubectl', 'apply', '-f', temp_file],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            logger.info(f"✅ Created K8s CronJob {job_name} for {schedule}")
            return True
        else:
            logger.error(f"Failed to create CronJob: {result.stderr}")
            return False
    finally:
        os.unlink(temp_file)

def cleanup_old_jobs():
    """Remove completed/failed CronJobs for past races."""
    try:
        result = subprocess.run(
            ['kubectl', 'get', 'cronjobs', '-n', 'f1-predictor', 
             '-o', 'jsonpath={range .items[*]}{.metadata.name}{"\\n"}{end}'],
            capture_output=True, text=True
        )
        
        if result.returncode != 0:
            return
        
        jobs = result.stdout.strip().split('\n')
        for job in jobs:
            if job.startswith('f1-fetch-results-'):
                # Check if job has completed
                check_result = subprocess.run(
                    ['kubectl', 'get', 'cronjob', job, '-n', 'f1-predictor', 
                     '-o', 'jsonpath={.status.lastSuccessfulTime}'],
                    capture_output=True, text=True
                )
                if check_result.stdout.strip():
                    # Job succeeded, delete it
                    subprocess.run(
                        ['kubectl', 'delete', 'cronjob', job, '-n', 'f1-predictor'],
                        capture_output=True
                    )
                    logger.info(f"Cleaned up old CronJob: {job}")
    except Exception as e:
        logger.warning(f"Cleanup error (non-critical): {e}")

def main():
    """Main scheduler loop."""
    logger.info("Starting F1 race results scheduler")
    
    state = load_state()
    races = get_upcoming_races()
    
    if not races:
        logger.info("No upcoming races to schedule")
        return
    
    now = datetime.now()
    
    for race in races:
        race_id = race['id']
        
        # Skip if already scheduled
        if race_id in state.get('scheduled_jobs', []):
            continue
        
        race_time = datetime.strptime(race['date'], '%Y-%m-%d %H:%M:%S')
        
        # Only schedule if race is in the future or very recent
        if race_time > now - timedelta(hours=6):
            success = spawn_kubernetes_cronjob(
                race_id, 
                race['name'], 
                race['date']
            )
            
            if success:
                state['scheduled_jobs'].append(race_id)
                save_state(state)
    
    # Cleanup old jobs
    cleanup_old_jobs()
    
    logger.info("Scheduler completed")

if __name__ == '__main__':
    main()
