from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.services.firebase_service import verify_firebase_token

bearer_scheme = HTTPBearer()


def upsert_user_from_token(db: Session, decoded: dict) -> User:
    """依 Firebase token 內容建立或更新 user。

    /auth/verify 與 get_current_user 共用；IntegrityError 處理的是
    「同一個新使用者的兩個併發請求同時建立」的 race（第一次登入時常見）。
    """
    user = db.query(User).filter(User.firebase_uid == decoded["uid"]).first()
    if not user:
        try:
            user = User(
                firebase_uid=decoded["uid"],
                email=decoded.get("email", ""),
                display_name=decoded.get("name"),
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        except IntegrityError:
            db.rollback()
            user = db.query(User).filter(User.firebase_uid == decoded["uid"]).first()
    else:
        changed = False
        new_name = decoded.get("name")
        if new_name and user.display_name != new_name:
            user.display_name = new_name
            changed = True
        # email 也要同步：admin 判定（settings.admin_email）比對的是 DB 裡的 email，
        # 使用者在 Firebase 改信箱後若不同步，權限判斷會用到舊值。
        new_email = decoded.get("email")
        if new_email and user.email != new_email:
            user.email = new_email
            changed = True
        if changed:
            db.commit()
            db.refresh(user)
    return user


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials
    try:
        decoded = verify_firebase_token(token)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    return upsert_user_from_token(db, decoded)
