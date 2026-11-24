from pathlib import Path

from app.settings import API_DIR, Settings


def test_database_environment_path_is_relative_to_api(monkeypatch):
    monkeypatch.setenv("RAYRIDE_DATABASE_PATH", "data/custom.sqlite3")
    settings = Settings(_env_file=None)

    assert settings.database_path == Path("data/custom.sqlite3")
    assert settings.resolved_database_path == API_DIR / "data" / "custom.sqlite3"
