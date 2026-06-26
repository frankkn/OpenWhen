from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserVerifyRequest, UserOut
from app.services.firebase_service import verify_firebase_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/verify", response_model=UserOut)
def verify_and_upsert_user(body: UserVerifyRequest, db: Session = Depends(get_db)):
    try:
        decoded = verify_firebase_token(body.id_token)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))

    user = db.query(User).filter(User.firebase_uid == decoded["uid"]).first()
    if not user:
        user = User(
            firebase_uid=decoded["uid"],
            email=decoded.get("email", ""),
            display_name=decoded.get("name"),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        # 更新 display_name（如果有變）
        new_name = decoded.get("name")
        if new_name and user.display_name != new_name:
            user.display_name = new_name
            db.commit()
            db.refresh(user)

    return user
