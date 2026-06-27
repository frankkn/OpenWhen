from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user
from app.models.user import User
from app.scheduler import check_due_capsules

router = APIRouter(prefix="/admin", tags=["admin"])

ADMIN_EMAIL = "admin@admin.com"


@router.post("/check-notifications")
def trigger_check_notifications(user: User = Depends(get_current_user)):
    """手動觸發到期膠囊通知檢查（僅限管理員，用於測試）。"""
    if user.email != ADMIN_EMAIL:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="僅限管理員")
    return check_due_capsules()
