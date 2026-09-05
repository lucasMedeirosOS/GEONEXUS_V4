from sqlalchemy import create_engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from app.core.config import settings

database_url = settings.DATABASE_URL.replace(
	"+asyncpg", "+psycopg"
)
engine = create_engine(database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
	db: Session = SessionLocal()
	try:
		yield db
	finally:
		db.close()
