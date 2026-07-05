from pydantic_settings import BaseSettings, SettingsConfigDict


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
    # 預設為空 = 沒有管理員。要啟用 admin 功能必須明確設定 ADMIN_EMAIL，
    # 且應設成你真實擁有、可收信驗證的信箱（假信箱誰先註冊誰就是 admin）。
    admin_email: str = ""
    secret_key: str = "change-me-in-production"
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    # extra="ignore"：.env 或環境變數中多出來的 key（例如已棄用的 RESEND_API_KEY）
    # 不應讓 app 啟動失敗
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
