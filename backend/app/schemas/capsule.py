from datetime import datetime
from pydantic import BaseModel
from app.models.capsule import CapsuleMode, CapsuleStatus


class CapsuleAnswerIn(BaseModel):
    question_number: int
    question_text: str
    answer_text: str | None = None


class CapsuleAnswerOut(CapsuleAnswerIn):
    id: str
    capsule_id: str

    model_config = {"from_attributes": True}


class CapsuleCreate(BaseModel):
    title: str | None = None
    content: str
    mode: CapsuleMode
    open_date: datetime
    notification_email: str | None = None
    answers: list[CapsuleAnswerIn] = []


class CapsuleOut(BaseModel):
    id: str
    user_id: str
    title: str | None
    content: str
    mode: CapsuleMode
    status: CapsuleStatus
    open_date: datetime
    notification_email: str | None
    created_at: datetime
    opened_at: datetime | None
    answers: list[CapsuleAnswerOut] = []

    model_config = {"from_attributes": True}


class CapsuleListItem(BaseModel):
    id: str
    title: str | None
    mode: CapsuleMode
    status: CapsuleStatus
    open_date: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class ReflectionIn(BaseModel):
    question_text: str
    answer_text: str | None = None


class ReflectionOut(ReflectionIn):
    id: str
    capsule_id: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ReflectionSaveRequest(BaseModel):
    reflections: list[ReflectionIn]
