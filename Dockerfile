# Cloud Run 專用 Dockerfile。
# 因為本專案是 monorepo（backend 在 backend/ 子目錄），Cloud Run 的
# 「從 repo 持續部署」build context 是 repo 根目錄，所以這裡用 backend/ 前綴。
# 本地開發仍用 backend/Dockerfile（docker-compose 的 build: ./backend）。
FROM python:3.11-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

RUN chmod +x start.sh

# start.sh 會先跑 alembic upgrade head，再用 $PORT（Cloud Run 注入）起 uvicorn。
CMD ["./start.sh"]
