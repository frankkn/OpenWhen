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
            # 原子 claim：只有成功把 notification_sent_at 從 NULL 改成 now 的程序才寄信，
            # 避免多 worker 同時跑 scheduler 時重複寄信。
            claimed = (
                db.query(Capsule)
                .filter(
                    Capsule.id == capsule.id,
                    Capsule.notification_sent_at.is_(None),
                )
                .update({Capsule.notification_sent_at: now}, synchronize_session=False)
            )
            db.commit()
            if not claimed:
                continue  # 已被其他程序搶走

            try:
                created_str = capsule.created_at.strftime("%Y 年 %m 月 %d 日")
                send_capsule_ready_email(
                    to=capsule.notification_email,
                    capsule_title=capsule.title,
                    open_date=capsule.open_date,
                    created_at_str=created_str,
                )
                sent += 1
            except Exception as e:
                # 寄信失敗 → 還原 claim，讓下次重試
                db.query(Capsule).filter(Capsule.id == capsule.id).update(
                    {Capsule.notification_sent_at: None}, synchronize_session=False
                )
                db.commit()
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
