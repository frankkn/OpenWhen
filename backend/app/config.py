from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    firebase_project_id: str
    firebase_service_account_path: str = "./firebase-service-account.json"
    anthropic_api_key: str
    secret_key: str = "change-me-in-production"
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"

    @property
    def origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    class Config:
        env_file = ".env"


settings = Settings()
