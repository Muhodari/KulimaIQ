from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # MongoDB — local Docker or MongoDB Atlas (mongodb+srv://...)
    mongo_url: str = "mongodb://localhost:27017"
    mongo_db: str = "kulimaiq"

    # JWT
    secret_key: str = "CHANGE_ME_IN_PRODUCTION_USE_LONG_RANDOM_STRING"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080  # 7 days

    # ML
    model_weights_path: str = "model_weights/kulimaiq_mobilenet.pth"
    ml_confidence_threshold: float = 0.50

    # Server
    allowed_origins: list[str] = ["*"]


settings = Settings()
