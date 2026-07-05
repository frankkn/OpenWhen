from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import upsert_user_from_token
from app.schemas.user import UserOut, UserVerifyRequest
from app.services.firebase_service import verify_firebase_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/verify", response_model=UserOut)
def verify_and_upsert_user(body: UserVerifyRequest, db: Session = Depends(get_db)):
    try:
        decoded = verify_firebase_token(body.id_token)
    except ValueError as e:
        # verify_firebase_token 只會拋 ValueError（含友善訊息）；
        # 其他例外（例如 DB 掛掉）交給 FastAPI 回 500，避免把內部錯誤細節
        # 放進 response detail 洩漏給 client。
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    return upsert_user_from_token(db, decoded)
