from datetime import date, datetime, time
from pathlib import Path

from sqlalchemy import (
    URL,
    CheckConstraint,
    Date,
    DateTime,
    String,
    Time,
    create_engine,
    text,
)
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Reservation(Base):
    __tablename__ = "reservations"
    __table_args__ = (
        CheckConstraint("status = 'simulated'", name="reservation_simulated"),
    )

    reference: Mapped[str] = mapped_column(String(15), primary_key=True)
    flight_number: Mapped[str] = mapped_column(String(7))
    arrival_airport: Mapped[str] = mapped_column(String(3))
    arrival_date: Mapped[date] = mapped_column(Date)
    arrival_local_time: Mapped[time] = mapped_column(Time)
    destination: Mapped[str] = mapped_column(String(200))
    status: Mapped[str] = mapped_column(String(9), server_default="simulated")
    # SQLite CURRENT_TIMESTAMP is UTC. SQLite datetime storage has no offset.
    created_at_utc: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP")
    )


def initialize_database(path: Path) -> Engine:
    path.parent.mkdir(parents=True, exist_ok=True)
    engine = create_engine(URL.create("sqlite+pysqlite", database=str(path)))
    try:
        Base.metadata.create_all(engine)
    except Exception:
        engine.dispose()
        raise
    return engine
