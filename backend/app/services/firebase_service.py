import firebase_admin
from firebase_admin import credentials, auth

from app.config import settings

_app = None


def _get_app():
    global _app
    if _app is None:
        cred = credentials.Certificate(settings.firebase_service_account_path)
        _app = firebase_admin.initialize_app(cred)
    return _app


def verify_firebase_token(id_token: str) -> dict:
    _get_app()
    try:
        decoded = auth.verify_id_token(id_token)
        return decoded
    except auth.ExpiredIdTokenError:
        raise ValueError("Token 已過期，請重新登入")
    except auth.InvalidIdTokenError:
        raise ValueError("無效的 Token")
    except Exception as e:
        raise ValueError(f"Token 驗證失敗：{e}")
