import uuid
from datetime import datetime, date, timezone

from sqlalchemy import String, Text, Date, DateTime, Integer, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.database import Base


class CapsuleMode(str, enum.Enum):
    free = "free"
    ai_assisted = "ai_assisted"


class CapsuleStatus(str, enum.Enum):
    locked = "locked"
    opened = "opened"


class Capsule(Base):
    __tablename__ = "capsules"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False, index=True)
    title: Mapped[str | None] = mapped_column(String(200), nullable=True)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    mode: Mapped[CapsuleMode] = mapped_column(SAEnum(CapsuleMode), nullable=False)
    status: Mapped[CapsuleStatus] = mapped_column(SAEnum(CapsuleStatus), default=CapsuleStatus.locked, nullable=False)
    open_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    notification_email: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    opened_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    notification_sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="capsules")
    answers = relationship("CapsuleAnswer", back_populates="capsule", cascade="all, delete-orphan", order_by="CapsuleAnswer.question_number")
    reflections = relationship("Reflection", back_populates="capsule", cascade="all, delete-orphan")


class CapsuleAnswer(Base):
    __tablename__ = "capsule_answers"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    capsule_id: Mapped[str] = mapped_column(String, ForeignKey("capsules.id"), nullable=False, index=True)
    question_number: Mapped[int] = mapped_column(Integer, nullable=False)
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    answer_text: Mapped[str | None] = mapped_column(Text, nullable=True)

    capsule = relationship("Capsule", back_populates="answers")


class Reflection(Base):
    __tablename__ = "reflections"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    capsule_id: Mapped[str] = mapped_column(String, ForeignKey("capsules.id"), nullable=False, index=True)
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    answer_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    capsule = relationship("Capsule", back_populates="reflections")
