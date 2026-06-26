#!/bin/bash
set -e

# Write Firebase service account from env var to file (used in Railway/cloud)
if [ -n "$FIREBASE_SERVICE_ACCOUNT_JSON" ]; then
    TARGET="${FIREBASE_SERVICE_ACCOUNT_PATH:-./firebase-service-account.json}"
    echo "$FIREBASE_SERVICE_ACCOUNT_JSON" > "$TARGET"
fi

# Run database migrations
alembic upgrade head

# Start server (Railway injects $PORT automatically)
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
