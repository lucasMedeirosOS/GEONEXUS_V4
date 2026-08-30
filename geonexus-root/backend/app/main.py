from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.health import router as health_router
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
    description="API for geospatial and electoral analysis workflows.",
    openapi_url="/api/v1/openapi.json",
    docs_url="/docs",
)

if settings.CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(health_router, prefix="/api/v1")


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Geonexus backend is running."}
