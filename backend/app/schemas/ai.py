from pydantic import BaseModel
from app.schemas.capsule import CapsuleAnswerIn


class GenerateLetterRequest(BaseModel):
    answers: list[CapsuleAnswerIn]


class GenerateLetterResponse(BaseModel):
    letter: str


class GenerateReflectionsRequest(BaseModel):
    letter_content: str


class GenerateReflectionsResponse(BaseModel):
    questions: list[str]
