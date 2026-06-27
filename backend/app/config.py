from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    firebase_project_id: str
    firebase_service_account_path: str = "./firebase-service-account.json"
    # 若設定（例如 Railway 環境變數或本機用 `railway run`），優先使用此 JSON 字串，
    # 不需要本機的 firebase-service-account.json 檔案。
    firebase_service_account_json: str = ""
    gemini_api_key: str
    gemini_model: str = "gemini-2.5-flash"
    # Gmail SMTP（免費寄信，不需網域）。需在 Google 帳號開啟兩步驟驗證後產生「應用程式密碼」。
    gmail_address: str = ""
    gmail_app_password: str = ""
    admin_email: str = "admin@admin.com"
    secret_key: str = "change-me-in-production"
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    class Config:
        env_file = ".env"


settings = Settings()
