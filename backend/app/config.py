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
    # Email 通知用 Brevo HTTP API（免費、不需網域、走 HTTPS，Railway 不擋對外 SMTP）。
    # mail_from_email 需在 Brevo 後台驗證為寄件人。
    brevo_api_key: str = ""
    mail_from_email: str = ""
    mail_from_name: str = "OpenWhen"
    admin_email: str = "admin@admin.com"
    secret_key: str = "change-me-in-production"
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    class Config:
        env_file = ".env"


settings = Settings()
