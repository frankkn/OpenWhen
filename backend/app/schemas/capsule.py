from datetime import datetime, date
from pydantic import BaseModel, field_validator
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
    open_date: date
    notification_email: str | None = None
    answers: list[CapsuleAnswerIn] = []

    @field_validator("open_date")
    @classmethod
    def open_date_must_be_future(cls, v: date) -> date:
        from datetime import date as date_type
        min_date = date_type.today()
        from dateutil.relativedelta import relativedelta
        min_date = date_type.today()
        import datetime as dt
        min_allowed = dt.date.today() + dt.timedelta(days=90)
        if v < min_allowed:
            raise ValueError("開封日期最少需設定 3 個月後")
        return v


class CapsuleOut(BaseModel):
    id: str
    user_id: str
    title: str | None
    content: str
    mode: CapsuleMode
    status: CapsuleStatus
    open_date: date
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
    open_date: date
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
