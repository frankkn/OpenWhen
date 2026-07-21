from contextlib import asynccontextmanager

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.limiter import limiter
from app.routers import auth, capsules, ai, admin
from app.scheduler import start_scheduler, shutdown_scheduler, check_due_capsules


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Cloud Run 等 scale-to-zero 平台上關閉 in-process 排程器（ENABLE_SCHEDULER=false），
    # 改由外部 Cloud Scheduler 定時打 /internal/check-notifications。
    if settings.enable_scheduler:
        start_scheduler()
    yield
    if settings.enable_scheduler:
        shutdown_scheduler()


app = FastAPI(
    title="OpenWhen API",
    description="寫給未來自己的信 Backend",
    version="0.1.0",
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(capsules.router)
app.include_router(ai.router)
app.include_router(admin.router)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/internal/check-notifications")
def internal_check_notifications(x_cron_secret: str = Header(default="")):
    """外部排程器（Cloud Scheduler）觸發到期膠囊通知檢查。
    以共享密鑰 CRON_SECRET 保護；未設定 CRON_SECRET 時一律拒絕，避免被公開觸發。"""
    if not settings.cron_secret or x_cron_secret != settings.cron_secret:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return check_due_capsules()
