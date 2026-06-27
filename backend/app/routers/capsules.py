import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.capsule import Capsule, CapsuleAnswer, CapsuleStatus, Reflection
from app.schemas.capsule import (
    CapsuleCreate, CapsuleOut, CapsuleListItem,
    ReflectionOut, ReflectionSaveRequest,
)

router = APIRouter(prefix="/capsules", tags=["capsules"])


def _is_admin(user: User) -> bool:
    return bool(settings.admin_email) and user.email == settings.admin_email


def _ensure_aware(dt: datetime.datetime) -> datetime.datetime:
    """把 naive datetime 視為 UTC，確保比較時兩邊都帶時區。"""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=datetime.timezone.utc)
    return dt


def _validate_open_date(open_date: datetime.datetime, user: User) -> None:
    if _is_admin(user):
        return
    now = datetime.datetime.now(datetime.timezone.utc)
    open_date = _ensure_aware(open_date)
    min_date = now + datetime.timedelta(days=30)
    max_date = now + datetime.timedelta(days=365 * 100)
    if open_date < min_date:
        raise HTTPException(status_code=400, detail="開封日期最少需設定 1 個月後")
    if open_date > max_date:
        raise HTTPException(status_code=400, detail="開封日期最多設定 100 年後")


@router.get("", response_model=list[CapsuleListItem])
def list_capsules(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(Capsule).filter(Capsule.user_id == current_user.id).order_by(Capsule.created_at.desc()).all()


@router.post("", response_model=CapsuleOut, status_code=status.HTTP_201_CREATED)
def create_capsule(
    body: CapsuleCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _validate_open_date(body.open_date, current_user)

    capsule = Capsule(
        user_id=current_user.id,
        title=body.title,
        content=body.content,
        mode=body.mode,
        open_date=body.open_date,
        notification_email=body.notification_email,
        status=CapsuleStatus.locked,
    )
    db.add(capsule)
    db.flush()

    for ans in body.answers:
        db.add(CapsuleAnswer(
            capsule_id=capsule.id,
            question_number=ans.question_number,
            question_text=ans.question_text,
            answer_text=ans.answer_text,
        ))

    db.commit()
    db.refresh(capsule)
    return capsule


@router.get("/{capsule_id}", response_model=CapsuleOut)
def get_capsule(
    capsule_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return _get_owned_capsule(capsule_id, current_user.id, db)


@router.delete("/{capsule_id}", status_code=204)
def delete_capsule(
    capsule_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    capsule = _get_owned_capsule(capsule_id, current_user.id, db)
    db.delete(capsule)
    db.commit()


@router.post("/{capsule_id}/open", response_model=CapsuleOut)
def open_capsule(
    capsule_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    capsule = _get_owned_capsule(capsule_id, current_user.id, db)

    if capsule.status == CapsuleStatus.opened:
        raise HTTPException(status_code=400, detail="這封信已經開封過了")

    if not _is_admin(current_user):
        now = datetime.datetime.now(datetime.timezone.utc)
        open_date = _ensure_aware(capsule.open_date)
        if open_date > now:
            delta = open_date - now
            total_secs = int(delta.total_seconds())
            days_left = total_secs // 86400
            hours_left = (total_secs % 86400) // 3600
            mins_left = (total_secs % 3600) // 60
            if days_left > 0:
                detail = f"還沒到開封時間，還有 {days_left} 天 {hours_left} 小時"
            elif hours_left > 0:
                detail = f"還沒到開封時間，還有 {hours_left} 小時"
            else:
                detail = f"還沒到開封時間，還有 {mins_left} 分鐘"
            raise HTTPException(status_code=400, detail=detail)

    capsule.status = CapsuleStatus.opened
    capsule.opened_at = datetime.datetime.now(datetime.timezone.utc)
    db.commit()
    db.refresh(capsule)
    return capsule


@router.post("/{capsule_id}/reflections", response_model=list[ReflectionOut])
def save_reflections(
    capsule_id: str,
    body: ReflectionSaveRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    capsule = _get_owned_capsule(capsule_id, current_user.id, db)

    if capsule.status != CapsuleStatus.opened:
        raise HTTPException(status_code=400, detail="這封信尚未開封，無法儲存反思")

    db.query(Reflection).filter(Reflection.capsule_id == capsule_id).delete()

    new_reflections = []
    for r in body.reflections:
        ref = Reflection(
            capsule_id=capsule_id,
            question_text=r.question_text,
            answer_text=r.answer_text,
        )
        db.add(ref)
        new_reflections.append(ref)

    db.commit()
    for ref in new_reflections:
        db.refresh(ref)
    return new_reflections


def _get_owned_capsule(capsule_id: str, user_id: str, db: Session) -> Capsule:
    capsule = db.query(Capsule).filter(Capsule.id == capsule_id, Capsule.user_id == user_id).first()
    if not capsule:
        raise HTTPException(status_code=404, detail="找不到這封信")
    return capsule
