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
                    created_at_str=created_str,
                )
            except Exception as e:
                # 寄信失敗 → 還原 claim，讓下次重試
                db.query(Capsule).filter(Capsule.id == capsule.id).update(
                    {Capsule.notification_sent_at: None}, synchronize_session=False
                )
                db.commit()
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
