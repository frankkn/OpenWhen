import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.capsule import Capsule, CapsuleAnswer, CapsuleStatus, Reflection
from app.schemas.capsule import (
    CapsuleCreate, CapsuleOut, CapsuleListItem,
    ReflectionOut, ReflectionSaveRequest,
)

router = APIRouter(prefix="/capsules", tags=["capsules"])


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
    capsule = _get_owned_capsule(capsule_id, current_user.id, db)
    return capsule


@router.post("/{capsule_id}/open", response_model=CapsuleOut)
def open_capsule(
    capsule_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    capsule = _get_owned_capsule(capsule_id, current_user.id, db)

    if capsule.status == CapsuleStatus.opened:
        raise HTTPException(status_code=400, detail="膠囊已經開封過了")

    today = datetime.date.today()
    if capsule.open_date > today:
        days_left = (capsule.open_date - today).days
        raise HTTPException(status_code=400, detail=f"還沒到開封日期，還有 {days_left} 天")

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
        raise HTTPException(status_code=400, detail="膠囊尚未開封，無法儲存反思")

    # 清除舊的反思記錄後重新儲存
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
        raise HTTPException(status_code=404, detail="找不到這個膠囊")
    return capsule
