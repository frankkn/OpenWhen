import asyncio
import logging

from google import genai
from google.genai import types

from app.config import settings
from app.schemas.capsule import CapsuleAnswerIn

logger = logging.getLogger(__name__)


class AIServiceError(Exception):
    """AI 生成失敗時拋出，由 router 轉成友善的 HTTP 錯誤。"""

LETTER_SYSTEM_PROMPT = """你是一個溫暖、有文學感的寫作助手。
使用者剛剛回答了一系列關於自己當下生活的問題。
請根據這些回答，整理成一封寫給未來自己的信。
要求：
- 用第一人稱「我」寫
- 保留使用者原本的語氣和用字，不要過度文學化
- 信的結構：開頭描述現在的狀態 → 中間寫擔憂與期待 → 結尾留下對未來自己說的話
- 長度約 300～500 字
- 繁體中文"""

REFLECTION_SYSTEM_PROMPT = """你是一個溫柔的見證者。
使用者剛剛打開了一封幾年前寫給自己的信。
請根據信的內容，提出 3～5 個反思問題，幫助使用者對比當年與現在的自己。
要求：
- 問題要具體，直接引用信中的關鍵詞或情緒
- 語氣溫柔，不要說教
- 不要給答案或建議，只問問題
- 繁體中文
- 直接回傳問題清單，每個問題一行，前面加上數字編號（例如：1. ）"""


def _client() -> genai.Client:
    return genai.Client(api_key=settings.gemini_api_key)


def _generate(system_prompt: str, contents: str, max_tokens: int) -> str:
    """同步呼叫 Gemini，回傳純文字；失敗或空回應時拋 AIServiceError。"""
    try:
        client = _client()
        response = client.models.generate_content(
            model=settings.gemini_model,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                max_output_tokens=max_tokens,
            ),
        )
    except Exception as e:
        logger.exception("Gemini generate_content failed")
        raise AIServiceError(f"AI 服務暫時無法使用：{e}")

    text = response.text
    if not text or not text.strip():
        raise AIServiceError("AI 沒有回傳內容，請稍後再試")
    return text


async def generate_letter(answers: list[CapsuleAnswerIn]) -> str:
    qa_text = "\n".join(
        f"Q{a.question_number}. {a.question_text}\nA: {a.answer_text or '（跳過）'}"
        for a in answers
    )
    # 同步 SDK 呼叫放到 thread，避免阻塞 FastAPI event loop
    return await asyncio.to_thread(
        _generate,
        LETTER_SYSTEM_PROMPT,
        f"以下是使用者的回答：\n\n{qa_text}\n\n請整理成一封信。",
        1024,
    )


async def generate_reflections(letter_content: str) -> list[str]:
    raw = await asyncio.to_thread(
        _generate,
        REFLECTION_SYSTEM_PROMPT,
        f"這是使用者當年寫的信：\n\n{letter_content}\n\n請提出反思問題。",
        512,
    )
    questions = [
        line.strip()
        for line in raw.splitlines()
        if line.strip() and line.strip()[0].isdigit()
    ]
    if not questions:
        # 解析不到編號清單時，至少回傳非空行，避免前端拿到空陣列
        questions = [line.strip() for line in raw.splitlines() if line.strip()]
    return questions
