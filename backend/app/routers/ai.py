from fastapi import APIRouter, Depends, HTTPException

from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.ai import (
    GenerateLetterRequest, GenerateLetterResponse,
    GenerateReflectionsRequest, GenerateReflectionsResponse,
)
from app.services.claude_service import generate_letter, generate_reflections, AIServiceError

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/generate-letter", response_model=GenerateLetterResponse)
async def api_generate_letter(
    body: GenerateLetterRequest,
    _: User = Depends(get_current_user),
):
    if not body.answers:
        raise HTTPException(status_code=400, detail="請提供至少一個問答")
    try:
        letter = await generate_letter(body.answers)
    except AIServiceError as e:
        raise HTTPException(status_code=503, detail=str(e))
    return GenerateLetterResponse(letter=letter)


@router.post("/generate-reflections", response_model=GenerateReflectionsResponse)
async def api_generate_reflections(
    body: GenerateReflectionsRequest,
    _: User = Depends(get_current_user),
):
    if not body.letter_content.strip():
        raise HTTPException(status_code=400, detail="信件內容不能為空")
    try:
        questions = await generate_reflections(body.letter_content)
    except AIServiceError as e:
        raise HTTPException(status_code=503, detail=str(e))
    return GenerateReflectionsResponse(questions=questions)
