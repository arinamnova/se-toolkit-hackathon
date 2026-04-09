import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from cat_manager.database import init_db
from cat_manager.routers import chat, pets, vet_visits
from cat_manager.settings import settings

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    logger.info("Database initialized")
    yield


app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    description="Cat Manager API — manage your pets and their vet visits.",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(pets.router, prefix="/pets", tags=["pets"])
app.include_router(vet_visits.router, prefix="/pets", tags=["vet-visits"])
app.include_router(chat.router, prefix="", tags=["chat"])


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}
