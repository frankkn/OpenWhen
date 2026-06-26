from datetime import datetime
from pydantic import BaseModel


class UserOut(BaseModel):
    id: str
    firebase_uid: str
    email: str
    display_name: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class UserVerifyRequest(BaseModel):
    id_token: str
