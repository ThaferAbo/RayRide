from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

API_DIR = Path(__file__).resolve().parents[1]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="RAYRIDE_",
        env_file=API_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_path: Path = Path("data/rayride.sqlite3")
    tesseract_executable: str = "tesseract"
    ocr_timeout_seconds: float = Field(default=8, gt=0, le=30)

    @property
    def resolved_database_path(self) -> Path:
        return (API_DIR / self.database_path).resolve()
