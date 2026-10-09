import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()

# Defaults to a local Postgres. docker-compose overrides this to point at the "db" service.
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://brian:password@localhost:5432/campusconnect"
)

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


# Dependency — gives each route its own DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
