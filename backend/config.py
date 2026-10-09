import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()

DEFAULT_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7


@dataclass(frozen=True)
class Settings:
    database_url: str
    secret_key: str
    token_expire_minutes: int
    cors_origins: tuple[str, ...]
    db_pool_size: int
    db_max_overflow: int


def get_settings() -> Settings:
    secret_key = os.getenv("SECRET_KEY")
    if not secret_key:
        raise RuntimeError("SECRET_KEY environment variable is not set")

    origins = os.getenv("CORS_ORIGINS", "*")
    return Settings(
        database_url=os.getenv(
            "DATABASE_URL",
            "postgresql://brian:password@localhost:5432/campusconnect",
        ),
        secret_key=secret_key,
        token_expire_minutes=int(os.getenv("TOKEN_EXPIRE_MINUTES", DEFAULT_TOKEN_EXPIRE_MINUTES)),
        cors_origins=tuple(o.strip() for o in origins.split(",") if o.strip()),
        db_pool_size=int(os.getenv("DB_POOL_SIZE", "10")),
        db_max_overflow=int(os.getenv("DB_MAX_OVERFLOW", "20")),
    )
