import logging
from datetime import datetime, timezone

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.capsule import Capsule, CapsuleStatus
from app.services.email_service import send_capsule_ready_email

logger = logging.getLogger(__name__)
_scheduler = BackgroundScheduler()


def check_due_capsules() -> dict:
    """檢查到期且需通知的信件並寄信。回傳 {'sent': N, 'failed': N}。"""
    from app.config import settings  # 避免循環 import
    if not settings.brevo_api_key or not settings.mail_from_email:
        logger.warning("Brevo 未設定（缺少 BREVO_API_KEY 或 MAIL_FROM_EMAIL），跳過本次通知檢查")
        return {"sent": 0, "failed": 0}

    db: Session = SessionLocal()
    sent = 0
    failed = 0
    try:
        now = datetime.now(timezone.utc)
        due = (
            db.query(Capsule)
            .filter(
                Capsule.status == CapsuleStatus.locked,
                Capsule.notification_email.isnot(None),
                Capsule.notification_sent_at.is_(None),
                Capsule.open_date <= now,
            )
            .all()
        )
        for capsule in due:
            try:
                created_str = capsule.created_at.strftime("%Y 年 %m 月 %d 日")
                send_capsule_ready_email(
                    to=capsule.notification_email,
                    capsule_title=capsule.title,
                    open_date=capsule.open_date,
                    created_at_str=created_str,
                )
                # 寄信成功後才寫入 notification_sent_at，確保 process crash 不會讓
                # capsule 永久消失在排程佇列中（寫入前 crash → 下次重試）。
                # 注意：多 worker 情境下仍有極小機率重複寄信；若日後橫向擴展，
                # 需改用獨立的 notification_claimed_at 欄位做原子 claim。
                db.query(Capsule).filter(
                    Capsule.id == capsule.id,
                    Capsule.notification_sent_at.is_(None),
                ).update({Capsule.notification_sent_at: now}, synchronize_session=False)
                db.commit()
                sent += 1
            except Exception as e:
                db.rollback()
                failed += 1
                logger.error("Email failed for capsule %s: %s", capsule.id, e)
    finally:
        db.close()
    return {"sent": sent, "failed": failed}


def start_scheduler() -> None:
    if _scheduler.running:
        return
    # 每 5 分鐘檢查一次，next_run_time=now 確保 app 啟動後立刻執行第一次。
    # （原本每小時一次，到期後通知最糟要等近 1 小時才送出。）
    _scheduler.add_job(
        check_due_capsules,
        IntervalTrigger(minutes=5),
        id="notify_due_capsules",
        next_run_time=datetime.now(timezone.utc),
    )
    _scheduler.start()
    logger.info("Started — checking due capsules every 5 minutes")


def shutdown_scheduler() -> None:
    if _scheduler.running:
        _scheduler.shutdown()
