#!/bin/bash
set -e

# Firebase 服務帳號透過環境變數 FIREBASE_SERVICE_ACCOUNT_JSON 提供，
# 由 app 直接讀取，不需要寫成檔案。

# Run database migrations
alembic upgrade head

# Start server (Railway injects $PORT automatically)
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
