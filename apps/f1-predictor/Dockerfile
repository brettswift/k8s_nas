# F1 Predictor App
# trigger: image-refresh

# --- Base stage ---
FROM python:3.11-slim as base

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY src/ ./
COPY cron/ ./cron/

# Create data directory for SQLite
RUN mkdir -p /data

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DATABASE_PATH=/data/f1_predictions.db

# --- Test stage ---
FROM base as test

# Copy tests
COPY tests/ ./tests/

# Run tests
CMD ["pytest", "tests/unit", "-v"]

# --- Production stage ---
FROM base as production

ARG APP_VERSION=""
ENV APP_VERSION=$APP_VERSION

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

EXPOSE 5000

# Run with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "4", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
