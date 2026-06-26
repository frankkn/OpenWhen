from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.services.firebase_service import verify_firebase_token

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials
    try:
        decoded = verify_firebase_token(token)
    except ValueError as e:
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
    return user
