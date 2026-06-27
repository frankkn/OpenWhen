from fastapi import APIRouter, Depends, HTTPException, status

from app.config import settings
from app.dependencies import get_current_user, get_db
from app.models.capsule import Capsule
from app.models.user import User
from app.scheduler import check_due_capsules
from sqlalchemy.orm import Session

router = APIRouter(prefix="/admin", tags=["admin"])


@router.post("/check-notifications")
def trigger_check_notifications(user: User = Depends(get_current_user)):
    """手動觸發到期膠囊通知檢查（僅限管理員，用於測試）。"""
    admin_email = settings.admin_email
    if not admin_email or user.email != admin_email:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="僅限管理員")
    return check_due_capsules()


@router.get("/notification-status/{capsule_id}")
def get_notification_status(
    capsule_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """查看指定膠囊的通知狀態（僅限膠囊擁有者）。"""
    capsule = db.query(Capsule).filter(Capsule.id == capsule_id).first()
    if not capsule:
        raise HTTPException(status_code=404, detail="膠囊不存在")
    if capsule.user_id != user.id:
        raise HTTPException(status_code=403, detail="無權限")

    resend_configured = bool(settings.resend_api_key)

    return {
        "capsule_id": capsule_id,
        "notification_email": capsule.notification_email,
        "notification_sent_at": capsule.notification_sent_at,
        "open_date": capsule.open_date,
        "status": capsule.status,
        "resend_configured": resend_configured,
        "diagnosis": _diagnose(capsule, resend_configured),
    }


def _diagnose(capsule: Capsule, resend_configured: bool) -> list[str]:
    from datetime import datetime, timezone
    issues = []
    if not capsule.notification_email:
        issues.append("notification_email 未設定：建立膠囊時沒有開啟 Email 通知開關")
    if not resend_configured:
        issues.append("RESEND_API_KEY 未設定：Railway 環境變數缺少此設定")
    if capsule.notification_sent_at:
        issues.append(f"通知已於 {capsule.notification_sent_at} 送出（不會重複寄）")
    now = datetime.now(timezone.utc)
    if capsule.open_date and capsule.open_date > now:
        issues.append(f"開封日期 {capsule.open_date} 尚未到，排程器不會寄信")
    if not issues:
        issues.append("設定看起來正常，等排程器下次執行（最多 1 小時）或請管理員手動觸發")
    return issues
