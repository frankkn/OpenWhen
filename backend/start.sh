#!/bin/bash
set -e

# Firebase 服務帳號透過環境變數 FIREBASE_SERVICE_ACCOUNT_JSON 提供，
# 由 app 直接讀取，不需要寫成檔案。

# Run database migrations
alembic upgrade head

# Start server (Render injects $PORT automatically)
# --proxy-headers：Render 在 proxy 之後，沒有這個的話 request.client.host
# 永遠是 proxy IP，slowapi 的 per-IP rate limit 會變成「全部使用者共用一個配額」。
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}" \
    --proxy-headers --forwarded-allow-ips="*"
