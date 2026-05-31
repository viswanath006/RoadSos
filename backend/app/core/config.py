from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://roadsos:roadsos_secret@localhost:5432/roadsos"
    secret_key: str = "roadsos-hackathon-secret-key-change-in-prod"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    cors_origins: list[str] = ["*"]
    sos_default_radius_m: int = 10000


settings = Settings()
