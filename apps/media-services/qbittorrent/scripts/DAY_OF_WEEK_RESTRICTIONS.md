# Day-of-Week Restrictions for F1 Torrent Scraper

## Requirements
- Run only on Thursday, Friday, Saturday, and Sunday
- If a download happens on Sunday, stop checking until Thursday

## Proposed Implementation Approach

### 1. CronJob Schedule Restriction
- Change schedule from `0 * * * *` (every hour) to `0 * * * 0,4,5,6` (Thu/Fri/Sat/Sun only)
- This prevents the job from even running on Mon-Wed

### 2. Sunday Download → Stop Until Thursday Logic
- Track `last_download_day` in state JSON (0=Monday, 6=Sunday)
- At script startup, check: if `last_download_day == 6` (Sunday) and today is Mon/Tue/Wed, exit early
- On Thursday, the check fails (today is Thursday, not Mon-Wed), so it runs normally

### State Structure
```json
{
  "seen_torrents": [...],
  "last_download_day": 6  // 0=Mon, 6=Sun
}
```

### Why This Is Simple
- No complex state machine
- Single check at startup
- CronJob schedule prevents Mon-Wed runs
- Script check is safety net if manually triggered

### Alternative Options Considered
1. **CronJob schedule only** - No script check needed (simplest, but no safety net)
2. **Track last download date** - More flexible but more complex
3. **Pause flag** - Use `"paused_until_thursday": true` that clears on Thursday

## Implementation Notes
- Python's `datetime.weekday()` returns: 0=Monday, 1=Tuesday, 2=Wednesday, 3=Thursday, 4=Friday, 5=Saturday, 6=Sunday
- Cron format: `0 * * * 0,4,5,6` where 0=Sunday, 4=Thursday, 5=Friday, 6=Saturday

