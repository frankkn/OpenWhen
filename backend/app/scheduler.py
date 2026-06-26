from datetime import datetime, timezone

from apscheduler.schedulers.background import BackgroundScheduler
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.capsule import Capsule, CapsuleStatus
from app.services.email_service import send_capsule_ready_email

_scheduler = BackgroundScheduler()


def _check_and_notify() -> None:
    db: Session = SessionLocal()
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
                    created_at_str=created_str,
                )
                capsule.notification_sent_at = now
                db.commit()
            except Exception as e:
                print(f"[scheduler] email failed for capsule {capsule.id}: {e}")
    finally:
        db.close()


def start_scheduler() -> None:
    if _scheduler.running:
        return
    # 每小時整點檢查一次（開發時用），正式環境可改為每天 08:00
    _scheduler.add_job(_check_and_notify, "interval", hours=1, id="notify_due_capsules")
    _scheduler.start()
    print("[scheduler] started — checking due capsules every hour")


def shutdown_scheduler() -> None:
    if _scheduler.running:
        _scheduler.shutdown()
