# Cat Manager — Project Context

> This file contains ALL information needed to implement the "Cat Manager" project from scratch in a fresh repository. It documents the full stack setup, architectural patterns, and step-by-step plan. A new agent with no access to Lab 8 should be able to build the entire project using only this file.

---

## Project Overview

**End user:** Pet owners who want a single place to manage their pets' care schedule.

**Problem:** It's easy to forget when you last took your pet to the vet but this is important to care about your pets.

**Project idea:** A chat-based pet profile manager where you remember when you took each of your pets to the vet. Receive smart recommendations from AI about when to take them to the vet again.

**Core feature:** Add your pets (name, breed, age) and save when you last took them to the vet (date is saved).

**Additional feature:** Ask AI when you should next take them to the vet.

---

## Required Components (per Hackathon spec)

The product must have:

1. **Backend** — FastAPI REST API (Python)
2. **Database** — PostgreSQL
3. **End-user-facing client** — Flutter web chat app
4. **AI/LLM integration** — Qwen Code API (OpenAI-compatible proxy)

---

## Full Architecture

```
browser → caddy → flutter web client (UI)
                → cat-manager backend (REST API)
                → qwen-code-api (LLM proxy → Qwen)

caddy → backend: HTTP REST
caddy → flutter: static files
caddy → qwen-code-api: HTTP (if needed directly)

backend → postgres: SQL (via SQLModel/SQLAlchemy)
backend → qwen-code-api: HTTP (OpenAI-compatible API calls)
```

### Request flows

1. **Add pet:** browser → caddy → `POST /pets` → postgres → response
2. **Save vet visit:** browser → caddy → `POST /pets/{id}/vet-visits` → postgres → response
3. **Chat with AI about pet:** browser → caddy → `POST /chat` → backend sends pet context + user message to qwen-code-api → qwen-code-api → Qwen → response back through chain
4. **View pet history:** browser → caddy → `GET /pets/{id}` → postgres → response

---

## Tech Stack

| Component | Technology | Version/Pattern |
|-----------|-----------|-----------------|
| Backend | FastAPI + SQLModel (SQLAlchemy) + Uvicorn | Python 3.14 |
| Database | PostgreSQL | 18.x Alpine |
| LLM Proxy | Qwen Code API | OpenAI-compatible |
| Client | Flutter web | Pre-built from nanobot-websocket-channel |
| Reverse Proxy | Caddy | 2.11 Alpine |
| Container orchestration | Docker Compose | v2 |
| Package management | uv (astral) | workspace mode |

---

## What to Reuse from Lab 8

### Reuse as-is (copy the patterns)

| Component | Where to find in Lab 8 | What to copy |
|-----------|----------------------|-------------|
| **Dockerfile pattern** | `backend/Dockerfile` | Multi-stage uv build, non-root user, `UV_COMPILE_BYTECODE=1`, `UV_LINK_MODE=copy`, `UV_NO_DEV=1` |
| **FastAPI app pattern** | `backend/src/lms_backend/main.py` | Lifespan, exception handler, request logging middleware, CORS, router includes |
| **Database setup** | `backend/src/lms_backend/database.py` | SQLModel engine creation, async session |
| **Settings pattern** | `backend/src/lms_backend/settings.py` | Pydantic Settings, reads from env vars |
| **Auth pattern** | `backend/src/lms_backend/auth.py` | Bearer API key verification |
| **Router pattern** | `backend/src/lms_backend/routers/*.py` | APIRouter, Depends for DB session, Pydantic schemas |
| **pyproject.toml** | `backend/pyproject.toml` | Dependencies, build-system, setuptools config |
| **Docker Compose** | `docker-compose.yml` | postgres, caddy, qwen-code-api services — copy and adapt |
| **Caddyfile** | `caddy/Caddyfile` | Reverse proxy patterns, `handle` directives |
| **Flutter client** | `nanobot-websocket-channel/client-web-flutter/` | Pre-built Flutter web app, just needs to be compiled and served |
| **.env.docker.example** | `.env.docker.example` | Environment variable template |
| **.dockerignore** | `.dockerignore` | Docker ignore patterns |
| **.gitignore** | `.gitignore` | Git ignore patterns |

---

## Database Schema

### Table: `pets`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | Primary Key, auto-increment |
| `name` | VARCHAR | NOT NULL |
| `species` | VARCHAR | NOT NULL (e.g., "cat", "dog") |
| `breed` | VARCHAR | nullable |
| `age` | FLOAT | nullable |
| `health_notes` | TEXT | nullable |
| `created_at` | TIMESTAMP | NOT NULL, default NOW() |

### Table: `vet_visits`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | Primary Key, auto-increment |
| `pet_id` | INTEGER | Foreign Key → pets.id, NOT NULL |
| `visit_date` | DATE | NOT NULL |
| `notes` | TEXT | nullable |
| `created_at` | TIMESTAMP | NOT NULL, default NOW() |

### Table: `reminders`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | Primary Key, auto-increment |
| `pet_id` | INTEGER | Foreign Key → pets.id, NOT NULL |
| `reminder_type` | VARCHAR | NOT NULL (e.g., "vet_checkup", "food_restock", "vaccination") |
| `due_date` | DATE | NOT NULL |
| `message` | TEXT | NOT NULL |
| `is_active` | BOOLEAN | NOT NULL, default true |
| `created_at` | TIMESTAMP | NOT NULL, default NOW() |

---

## Backend API Endpoints

All endpoints return JSON. No auth needed for the hackathon (keep it simple).

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|-------------|----------|
| `GET` | `/health` | Health check | — | `{"status": "ok"}` |
| `GET` | `/pets` | List all pets | — | `[PetOut]` |
| `POST` | `/pets` | Add a new pet | `PetIn {name, species, breed?, age?, health_notes?}` | `PetOut` |
| `GET` | `/pets/{pet_id}` | Get one pet | — | `PetOut` |
| `GET` | `/pets/{pet_id}/vet-visits` | List vet visits for a pet | — | `[VetVisitOut]` |
| `POST` | `/pets/{pet_id}/vet-visits` | Record a vet visit | `VetVisitIn {visit_date, notes?}` | `VetVisitOut` |
| `GET` | `/pets/{pet_id}/reminders` | List active reminders | — | `[ReminderOut]` |
| `POST` | `/chat` | Chat with AI about pets | `ChatIn {message, pet_id?}` | `ChatOut {response}` |
| `POST` | `/pets/{pet_id}/generate-reminders` | Ask AI to generate reminders based on pet data | — | `[ReminderOut]` |

---

## Project File Structure

```
cat-manager/
├── .env.docker.example          # Template for secrets
├── .env.docker.secret           # Actual secrets (gitignored)
├── .dockerignore
├── .gitignore
├── docker-compose.yml
├── pyproject.toml               # uv workspace root
├── uv.lock
│
├── backend/                     # Cat Manager FastAPI backend
│   ├── Dockerfile
│   ├── pyproject.toml
│   └── src/
│       └── cat_manager/
│           ├── __init__.py
│           ├── main.py           # FastAPI app, lifespan, middleware, routers
│           ├── settings.py       # Pydantic Settings
│           ├── database.py       # SQLModel engine + session
│           ├── models.py         # SQLModel table definitions
│           ├── schemas.py        # Pydantic request/response schemas
│           └── routers/
│               ├── __init__.py
│               ├── pets.py       # Pet CRUD endpoints
│               ├── vet_visits.py # Vet visit endpoints
│               ├── reminders.py  # Reminder endpoints
│               └── chat.py       # AI chat endpoint
│
├── caddy/
│   └── Caddyfile                # Reverse proxy config
│
├── client-web-flutter/          # Flutter web client (from submodule or copied)
│   └── ...                      # Pre-built Flutter project
│
└── scripts/
    └── init.sql                 # Database initialization script
```

---

## Detailed Implementation Guide

### Step 1: Environment Setup

Create `.env.docker.secret`:

```env
# Docker image registry
REGISTRY_PREFIX_DOCKER_HUB=

# Cat Manager Backend
BACKEND_NAME="Cat Manager Service"
BACKEND_DEBUG=false
BACKEND_RELOAD=false
BACKEND_CORS_ORIGINS=["*"]
BACKEND_CONTAINER_ADDRESS=0.0.0.0
BACKEND_CONTAINER_PORT=8000
BACKEND_HOST_ADDRESS=127.0.0.1
BACKEND_HOST_PORT=42001

# PostgreSQL
POSTGRES_DB=db-cat-manager
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST_ADDRESS=127.0.0.1
POSTGRES_HOST_PORT=42004

# Caddy
CADDY_CONTAINER_PORT=80
GATEWAY_HOST_ADDRESS=0.0.0.0
GATEWAY_HOST_PORT=42002

# Qwen Code API
QWEN_CODE_API_CONTAINER_ADDRESS=0.0.0.0
QWEN_CODE_API_CONTAINER_PORT=8080
QWEN_CODE_API_HOST_ADDRESS=127.0.0.1
QWEN_CODE_API_HOST_PORT=42005
QWEN_CODE_API_MODEL=coder-model
QWEN_CODE_API_LOG_LEVEL=error
QWEN_CODE_API_MAX_RETRIES=5
QWEN_CODE_API_RETRY_DELAY_MS=1000
QWEN_CODE_API_AUTH_USE=true
QWEN_CODE_API_LOG_REQUESTS=true
QWEN_CODE_API_KEY=<your-qwen-api-key>

# LLM API (used by backend to call Qwen)
LLM_API_KEY=${QWEN_CODE_API_KEY}
LLM_API_BASE_URL=http://qwen-code-api:8080/v1
LLM_API_MODEL=${QWEN_CODE_API_MODEL}
```

### Step 2: Database Init Script

Create `scripts/init.sql`:

```sql
CREATE TABLE IF NOT EXISTS pets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    species VARCHAR(100) NOT NULL,
    breed VARCHAR(255),
    age FLOAT,
    health_notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vet_visits (
    id SERIAL PRIMARY KEY,
    pet_id INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    visit_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reminders (
    id SERIAL PRIMARY KEY,
    pet_id INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    reminder_type VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    message TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Step 3: Backend pyproject.toml

```toml
[project]
name = "cat-manager-backend"
version = "0.1.0"
description = "Cat Manager Backend API"
requires-python = "==3.14.*"
dependencies = [
    "asyncpg>=0.30.0",
    "fastapi==0.128.7",
    "httpx==0.28.1",
    "pydantic==2.12.5",
    "pydantic-settings==2.12.0",
    "sqlmodel>=0.0.22",
    "uvicorn[standard]==0.40.0",
]

[build-system]
requires = ["setuptools>=75.0"]
build-backend = "setuptools.build_meta"

[tool.setuptools]
package-dir = { "" = "src" }

[tool.setuptools.packages.find]
where = ["src"]
include = ["cat_manager*"]
```

### Step 4: Backend Settings (`src/cat_manager/settings.py`)

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "Cat Manager Service"
    debug: bool = False
    cors_origins: list[str] = ["*"]
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "db-cat-manager"
    db_user: str = "postgres"
    db_password: str = "postgres"
    llm_api_key: str = ""
    llm_api_base_url: str = "http://qwen-code-api:8080/v1"
    llm_api_model: str = "coder-model"

    @property
    def database_url(self) -> str:
        return f"postgresql+asyncpg://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
```

### Step 5: Backend Database (`src/cat_manager/database.py`)

```python
from sqlmodel import SQLModel, create_engine
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from cat_manager.settings import settings

engine = create_async_engine(settings.database_url, echo=settings.debug)
async_session_maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

async def get_session():
    async with async_session_maker() as session:
        yield session
```

### Step 6: Backend Models (`src/cat_manager/models.py`)

```python
from datetime import date, datetime
from sqlmodel import Field, SQLModel, Relationship

class Pet(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str
    species: str
    breed: str | None = None
    age: float | None = None
    health_notes: str | None = None
    created_at: datetime = Field(default_factory=datetime.now)

    vet_visits: list["VetVisit"] = Relationship(back_populates="pet", cascade_delete=True)
    reminders: list["Reminder"] = Relationship(back_populates="pet", cascade_delete=True)

class VetVisit(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    pet_id: int = Field(foreign_key="pet.id", ondelete="CASCADE")
    visit_date: date
    notes: str | None = None
    created_at: datetime = Field(default_factory=datetime.now)

    pet: Pet = Relationship(back_populates="vet_visits")

class Reminder(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    pet_id: int = Field(foreign_key="pet.id", ondelete="CASCADE")
    reminder_type: str
    due_date: date
    message: str
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.now)

    pet: Pet = Relationship(back_populates="reminders")
```

### Step 7: Backend Schemas (`src/cat_manager/schemas.py`)

```python
from datetime import date, datetime
from pydantic import BaseModel

# Pet schemas
class PetIn(BaseModel):
    name: str
    species: str
    breed: str | None = None
    age: float | None = None
    health_notes: str | None = None

class PetOut(BaseModel):
    id: int
    name: str
    species: str
    breed: str | None
    age: float | None
    health_notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}

# Vet visit schemas
class VetVisitIn(BaseModel):
    visit_date: date
    notes: str | None = None

class VetVisitOut(BaseModel):
    id: int
    pet_id: int
    visit_date: date
    notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}

# Reminder schemas
class ReminderOut(BaseModel):
    id: int
    pet_id: int
    reminder_type: str
    due_date: date
    message: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}

# Chat schemas
class ChatIn(BaseModel):
    message: str
    pet_id: int | None = None

class ChatOut(BaseModel):
    response: str
```

### Step 8: Backend Routers

**`routers/pets.py`:**

```python
from fastapi import APIRouter, Depends
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from cat_manager.database import get_session
from cat_manager.models import Pet
from cat_manager.schemas import PetIn, PetOut

router = APIRouter()

@router.get("/", response_model=list[PetOut])
async def list_pets(session: AsyncSession = Depends(get_session)):
    result = await session.exec(select(Pet))
    return result.all()

@router.post("/", response_model=PetOut, status_code=201)
async def create_pet(pet: PetIn, session: AsyncSession = Depends(get_session)):
    db_pet = Pet.model_validate(pet)
    session.add(db_pet)
    await session.commit()
    await session.refresh(db_pet)
    return db_pet

@router.get("/{pet_id}", response_model=PetOut)
async def get_pet(pet_id: int, session: AsyncSession = Depends(get_session)):
    result = await session.exec(select(Pet).where(Pet.id == pet_id))
    return result.one()
```

**`routers/vet_visits.py`:**

```python
from fastapi import APIRouter, Depends
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from cat_manager.database import get_session
from cat_manager.models import VetVisit
from cat_manager.schemas import VetVisitIn, VetVisitOut

router = APIRouter()

@router.get("/{pet_id}/vet-visits", response_model=list[VetVisitOut])
async def list_visits(pet_id: int, session: AsyncSession = Depends(get_session)):
    result = await session.exec(select(VetVisit).where(VetVisit.pet_id == pet_id).order_by(VetVisit.visit_date.desc()))
    return result.all()

@router.post("/{pet_id}/vet-visits", response_model=VetVisitOut, status_code=201)
async def create_visit(pet_id: int, visit: VetVisitIn, session: AsyncSession = Depends(get_session)):
    db_visit = VetVisit(pet_id=pet_id, **visit.model_dump())
    session.add(db_visit)
    await session.commit()
    await session.refresh(db_visit)
    return db_visit
```

**`routers/reminders.py`:**

```python
from fastapi import APIRouter, Depends
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from cat_manager.database import get_session
from cat_manager.models import Reminder
from cat_manager.schemas import ReminderOut

router = APIRouter()

@router.get("/{pet_id}/reminders", response_model=list[ReminderOut])
async def list_reminders(pet_id: int, session: AsyncSession = Depends(get_session)):
    result = await session.exec(select(Reminder).where(Reminder.pet_id == pet_id, Reminder.is_active == True))
    return result.all()
```

**`routers/chat.py`:**

```python
import httpx
from fastapi import APIRouter, Depends
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from cat_manager.database import get_session
from cat_manager.models import Pet, VetVisit
from cat_manager.schemas import ChatIn, ChatOut
from cat_manager.settings import settings

router = APIRouter()

@router.post("/chat", response_model=ChatOut)
async def chat(chat_in: ChatIn, session: AsyncSession = Depends(get_session)):
    # Build context from pet data if pet_id is provided
    context = ""
    if chat_in.pet_id:
        result = await session.exec(select(Pet).where(Pet.id == chat_in.pet_id))
        pet = result.one_or_none()
        if pet:
            visits_result = await session.exec(
                select(VetVisit).where(VetVisit.pet_id == pet.id).order_by(VetVisit.visit_date.desc()).limit(5)
            )
            visits = visits_result.all()
            visit_history = "\n".join([f"- {v.visit_date}: {v.notes or 'Regular checkup'}" for v in visits])
            context = (
                f"Pet info: {pet.name} is a {pet.age or 'unknown'} year old {pet.breed or pet.species}."
            )
            if visit_history:
                context += f"\nRecent vet visits:\n{visit_history}"
            if pet.health_notes:
                context += f"\nHealth notes: {pet.health_notes}"
            context += "\n\n"

    system_prompt = (
        f"{context}You are a helpful and friendly pet care assistant. "
        f"Answer the user's question based on the pet information above. "
        f"If no pet info is available, still answer general pet care questions. "
        f"Be concise and helpful."
    )

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.llm_api_base_url}/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.llm_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.llm_api_model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": chat_in.message},
                ],
            },
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()
        answer = data["choices"][0]["message"]["content"]

    return ChatOut(response=answer)
```

### Step 9: Backend Main (`src/cat_manager/main.py`)

```python
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from cat_manager.database import init_db
from cat_manager.routers import chat, pets, reminders, vet_visits
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
app.include_router(reminders.router, prefix="/pets", tags=["reminders"])
app.include_router(chat.router, prefix="", tags=["chat"])

@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}
```

### Step 10: Backend Dockerfile

```dockerfile
ARG REGISTRY_PREFIX_DOCKER_HUB
FROM ${REGISTRY_PREFIX_DOCKER_HUB}astral/uv:python3.14-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
ENV UV_NO_DEV=1
ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /app
COPY pyproject.toml uv.lock /app/
COPY pyproject.toml /app/backend/pyproject.toml

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-workspace --package cat-manager-backend

COPY . /app/backend

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --package cat-manager-backend

# ---
ARG REGISTRY_PREFIX_DOCKER_HUB
FROM ${REGISTRY_PREFIX_DOCKER_HUB}python:3.14.2-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8

RUN groupadd --system --gid 999 nonroot \
    && useradd --system --gid 999 --uid 999 --create-home nonroot

COPY --from=builder --chown=nonroot:nonroot /app /app

ENV PATH="/app/.venv/bin:$PATH"
USER nonroot
WORKDIR /app

CMD ["uvicorn", "cat_manager.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Step 11: Backend Run Entry Point

Create `src/cat_manager/run.py` (for dev mode):

```python
import uvicorn
from cat_manager.settings import settings

if __name__ == "__main__":
    uvicorn.run(
        "cat_manager.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
    )
```

### Step 12: Root pyproject.toml (workspace)

```toml
[tool.uv.workspace]
members = [
    "backend",
]

[dependency-groups]
dev = [
    "poethepoet==0.42.1",
    "pyright==1.1.408",
    "pytest==9.0.2",
    "pytest-asyncio==1.3.0",
    "ruff==0.15.8",
    "ty==0.0.26",
]

[tool.poe.tasks]
[tool.poe.tasks.dev]
help = "Run server"
cmd = "python -m cat_manager.run"
env = { PYTHONPATH = "backend/src" }

[tool.poe.tasks.check]
help = "Format, lint, typecheck"
sequence = ["format", "lint", "typecheck"]

[tool.poe.tasks.format]
help = "Run the 'ruff' formatter"
cmd = "ruff format"

[tool.poe.tasks.lint]
help = "Run the 'ruff' linter"
cmd = "ruff check"

[tool.poe.tasks.typecheck]
help = "Run the 'ty' typechecker"
cmd = "ty check"

[tool.poe.tasks.test]
help = "Run all tests"
cmd = "pytest backend/tests"

[tool.ruff]
exclude = []

[tool.ruff.lint]
select = ["RET503"]

[tool.pyright]
include = ["backend"]
extraPaths = ["backend/src"]
exclude = ["**/__pycache__", "**/node_modules", "**/.*", ".venv", ".direnv"]
typeCheckingMode = "strict"
reportAssignmentType = "none"
reportIncompatibleVariableOverride = "none"
reportUnknownMemberType = "none"
reportMissingTypeStubs = "none"

[tool.pytest.ini_options]
testpaths = ["backend/tests"]
pythonpath = ["backend/src"]
asyncio_mode = "auto"

[tool.ty.src]
include = ["backend"]
```

### Step 13: Caddyfile

```
:{$CADDY_CONTAINER_PORT} {
    handle /pets* {
        reverse_proxy http://backend:{$BACKEND_CONTAINER_PORT}
    }
    handle /health {
        reverse_proxy http://backend:{$BACKEND_CONTAINER_PORT}
    }
    handle /chat {
        reverse_proxy http://backend:{$BACKEND_CONTAINER_PORT}
    }
    handle /docs* {
        reverse_proxy http://backend:{$BACKEND_CONTAINER_PORT}
    }
    handle /openapi.json {
        reverse_proxy http://backend:{$BACKEND_CONTAINER_PORT}
    }
    handle_path /flutter* {
        root * /srv/flutter
        try_files {path} /index.html
        file_server
    }
    handle {
        root * /srv/react
        try_files {path} /index.html
        file_server
    }
}
```

### Step 14: docker-compose.yml

```yaml
services:
  backend:
    build:
      context: ./backend
      additional_contexts:
        workspace: .
      args:
        REGISTRY_PREFIX_DOCKER_HUB: ${REGISTRY_PREFIX_DOCKER_HUB:-}
    restart: unless-stopped
    networks:
      - cat-manager-network
    ports:
      - ${BACKEND_HOST_ADDRESS:?'BACKEND_HOST_ADDRESS is required'}:${BACKEND_HOST_PORT:?'BACKEND_HOST_PORT is required'}:${BACKEND_CONTAINER_PORT}
    environment:
      - NAME=${BACKEND_NAME:?'BACKEND_NAME is required'}
      - DEBUG=${BACKEND_DEBUG:?'BACKEND_DEBUG is required'}
      - ADDRESS=${BACKEND_CONTAINER_ADDRESS:?'BACKEND_CONTAINER_ADDRESS is required'}
      - PORT=${BACKEND_CONTAINER_PORT:?'BACKEND_CONTAINER_PORT is required'}
      - RELOAD=${BACKEND_RELOAD:?'BACKEND_RELOAD is required'}
      - UVICORN_HOST=${BACKEND_CONTAINER_ADDRESS}
      - UVICORN_PORT=${BACKEND_CONTAINER_PORT}
      - UVICORN_RELOAD=${BACKEND_RELOAD}
      - CORS_ORIGINS=${BACKEND_CORS_ORIGINS:-["*"]}
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${POSTGRES_DB:?'POSTGRES_DB is required'}
      - DB_USER=${POSTGRES_USER:?'POSTGRES_USER is required'}
      - DB_PASSWORD=${POSTGRES_PASSWORD:?'POSTGRES_PASSWORD is required'}
      - LLM_API_KEY=${LLM_API_KEY:?'LLM_API_KEY is required'}
      - LLM_API_BASE_URL=http://qwen-code-api:${QWEN_CODE_API_CONTAINER_PORT:?'QWEN_CODE_API_CONTAINER_PORT is required'}/v1
      - LLM_API_MODEL=${LLM_API_MODEL:?'LLM_API_MODEL is required'}
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: ${REGISTRY_PREFIX_DOCKER_HUB:-}postgres:18.3-alpine
    restart: unless-stopped
    networks:
      - cat-manager-network
    environment:
      - POSTGRES_DB=${POSTGRES_DB:?'POSTGRES_DB is required'}
      - POSTGRES_USER=${POSTGRES_USER:?'POSTGRES_USER is required'}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:?'POSTGRES_PASSWORD is required'}
    ports:
      - ${POSTGRES_HOST_ADDRESS:?'POSTGRES_HOST_ADDRESS is required'}:${POSTGRES_HOST_PORT:?'POSTGRES_HOST_PORT is required'}:5432
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5

  caddy:
    image: ${REGISTRY_PREFIX_DOCKER_HUB:-}caddy:2.11-alpine
    networks:
      - cat-manager-network
    depends_on:
      - backend
    environment:
      - CADDY_CONTAINER_PORT=${CADDY_CONTAINER_PORT:?'CADDY_CONTAINER_PORT is required'}
      - BACKEND_CONTAINER_PORT=${BACKEND_CONTAINER_PORT:?'BACKEND_CONTAINER_PORT is required'}
    ports:
      - ${GATEWAY_HOST_ADDRESS:?'GATEWAY_HOST_ADDRESS is required'}:${GATEWAY_HOST_PORT:?'GATEWAY_HOST_PORT is required'}:${CADDY_CONTAINER_PORT}
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
      - client-web-flutter:/srv/flutter:ro

  qwen-code-api:
    build:
      context: ./qwen-code-api
      args:
        REGISTRY_PREFIX_DOCKER_HUB: ${REGISTRY_PREFIX_DOCKER_HUB:-}
    restart: unless-stopped
    networks:
      - cat-manager-network
    ports:
      - ${QWEN_CODE_API_HOST_ADDRESS:?'QWEN_CODE_API_HOST_ADDRESS is required'}:${QWEN_CODE_API_HOST_PORT:?'QWEN_CODE_API_HOST_PORT is required'}:${QWEN_CODE_API_CONTAINER_PORT:-8080}
    volumes:
      - ~/.qwen:/mnt/qwen-creds:ro
    environment:
      - PORT=${QWEN_CODE_API_CONTAINER_PORT:-8080}
      - ADDRESS=${QWEN_CODE_API_CONTAINER_ADDRESS:-0.0.0.0}
      - DEFAULT_MODEL=${QWEN_CODE_API_MODEL:?'QWEN_CODE_API_MODEL is required'}
      - LOG_LEVEL=${QWEN_CODE_API_LOG_LEVEL:?'QWEN_CODE_API_LOG_LEVEL is required'}
      - MAX_RETRIES=${QWEN_CODE_API_MAX_RETRIES:?'QWEN_CODE_API_MAX_RETRIES is required'}
      - RETRY_DELAY_MS=${QWEN_CODE_API_RETRY_DELAY_MS:?'QWEN_CODE_API_RETRY_DELAY_MS is required'}
      - QWEN_CODE_AUTH_USE=${QWEN_CODE_API_AUTH_USE:?'QWEN_CODE_API_AUTH_USE is required'}
      - LOG_REQUESTS=${QWEN_CODE_API_LOG_REQUESTS:?'QWEN_CODE_API_LOG_REQUESTS is required'}
      - QWEN_CODE_API_KEY=${QWEN_CODE_API_KEY:-}
    healthcheck:
      test:
        - CMD
        - python
        - "-c"
        - |
          import urllib.request
          req = urllib.request.Request(
              'http://localhost:${QWEN_CODE_API_CONTAINER_PORT:-8080}/health',
              headers={'X-API-Key': '${QWEN_CODE_API_KEY:-}'}
          )
          urllib.request.urlopen(req)
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  client-web-flutter:
    build:
      context: ./client-web-flutter
      args:
        REGISTRY_PREFIX_DOCKER_HUB: ${REGISTRY_PREFIX_DOCKER_HUB:-}
        REGISTRY_PREFIX_GHCR: ${REGISTRY_PREFIX_GHCR:-}
    volumes:
      - client-web-flutter:/output

volumes:
  postgres_data:
  client-web-flutter:

networks:
  cat-manager-network:
    name: cat-manager-network
    attachable: true
```

### Step 15: Flutter Client

The Flutter web client comes from the `nanobot-websocket-channel` submodule in Lab 8. In the new repo, you have two options:

**Option A — Copy the Flutter project:** Copy the entire `client-web-flutter/` directory from Lab 8's `nanobot-websocket-channel/client-web-flutter/`. It's a pre-built Flutter web app that provides a chat UI. It will need minimal modification — just point it at your backend's `/chat` endpoint instead of the nanobot WebSocket.

**Option B — Build a simple Flutter chat UI:** Create a minimal Flutter web app with:

- A login screen (optional, can skip auth for simplicity)
- A chat screen with: text input, send button, message list
- HTTP POST to `/chat` endpoint on submit

The Flutter `Dockerfile` pattern from Lab 8:

```dockerfile
ARG REGISTRY_PREFIX_DOCKER_HUB
ARG REGISTRY_PREFIX_GHCR
FROM ${REGISTRY_PREFIX_DOCKER_HUB}flutter:3.32.8 AS builder

WORKDIR /app
COPY . .
RUN flutter build web --release --output /output

FROM ${REGISTRY_PREFIX_DOCKER_HUB}alpine:3.22
RUN mkdir -p /output
COPY --from=builder /output /output
```

---

## Flutter Chat UI — Minimal Implementation

If building from scratch, here's the minimal Flutter web chat needed:

**`lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const CatManagerApp());

class CatManagerApp extends StatelessWidget {
  const CatManagerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Manager',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _messages = <Map<String, String>>[];
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _controller.clear();
    try {
      final resp = await http.post(
        Uri.parse('/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );
      final data = jsonDecode(resp.body);
      setState(() {
        _messages.add({'role': 'bot', 'content': data['response'] ?? 'No response'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'content': 'Error: $e'});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐱 Cat Manager')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(m['content'] ?? ''),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Ask about your pet...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_loading,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _send,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Reminder Generation Feature (Additional / Version 2)

### How it works

1. User clicks "Generate Reminders" for a pet (or sends a chat message requesting it)
2. Backend fetches pet info + vet visit history
3. Sends to Qwen API with a prompt like:

```
You are a pet care assistant. Based on this pet's information and vet visit history,
generate 2-3 useful reminders (vet checkup, food, vaccination, etc.).

Pet: {name}, {age} year old {breed/species}
Health notes: {health_notes}
Last vet visit: {last_visit_date}

Respond with a JSON array of objects: [{"type": "vet_checkup", "due_date": "2025-05-01", "message": "..."}]
```

1. Parse response, save reminders to DB, return to client

### Endpoint (`routers/reminders.py` addition)

```python
@router.post("/{pet_id}/generate-reminders", response_model=list[ReminderOut])
async def generate_reminders(pet_id: int, session: AsyncSession = Depends(get_session)):
    # Fetch pet info
    result = await session.exec(select(Pet).where(Pet.id == pet_id))
    pet = result.one_or_none()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")

    # Fetch last vet visits
    visits_result = await session.exec(
        select(VetVisit).where(VetVisit.pet_id == pet_id).order_by(VetVisit.visit_date.desc()).limit(3)
    )
    visits = visits_result.all()

    # Build prompt
    prompt = (
        f"You are a pet care assistant. Based on this pet's information and vet visit history, "
        f"generate 2-3 useful reminders (vet checkup, food, vaccination, etc.).\n\n"
        f"Pet: {pet.name}, {pet.age or 'unknown'} year old {pet.breed or pet.species}.\n"
        f"Health notes: {pet.health_notes or 'None'}.\n"
        f"Recent vet visits:\n"
    )
    for v in visits:
        prompt += f"  - {v.visit_date}: {v.notes or 'Regular checkup'}\n"
    if not visits:
        prompt += "  No recent vet visits recorded.\n"
    prompt += (
        f"\nRespond with a JSON array of objects with keys: "
        f'"reminder_type" (one of: vet_checkup, food_restock, vaccination, grooming, other), '
        f'"due_date" (YYYY-MM-DD format, roughly 1-6 months from now), '
        f'"message" (friendly reminder text). '
        f'Example: [{{"reminder_type": "vet_checkup", "due_date": "2025-06-01", "message": "Time for a checkup!"}}]'
    )

    # Call LLM
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{settings.llm_api_base_url}/chat/completions",
            headers={"Authorization": f"Bearer {settings.llm_api_key}", "Content-Type": "application/json"},
            json={"model": settings.llm_api_model, "messages": [{"role": "user", "content": prompt}]},
            timeout=30.0,
        )
        resp.raise_for_status()
        data = resp.json()
        content = data["choices"][0]["message"]["content"]

    # Parse and save
    import json
    reminders_data = json.loads(content)
    created = []
    for r in reminders_data:
        reminder = Reminder(
            pet_id=pet_id,
            reminder_type=r["reminder_type"],
            due_date=date.fromisoformat(r["due_date"]),
            message=r["message"],
        )
        session.add(reminder)
        created.append(reminder)
    await session.commit()
    for r in created:
        await session.refresh(r)
    return created
```

---

## Deployment Steps

1. **Clone the repo** with submodules (if using Flutter from nanobot-websocket-channel):

   ```sh
   git clone --recurse-submodules <your-repo-url> se-toolkit-hackathon
   cd se-toolkit-hackathon
   ```

2. **Install dependencies:**

   ```sh
   uv sync
   ```

3. **Create secrets file:**

   ```sh
   cp .env.docker.example .env.docker.secret
   # Edit .env.docker.secret: set QWEN_CODE_API_KEY, LLM_API_KEY
   ```

4. **Build and start:**

   ```sh
   docker compose --env-file .env.docker.secret build
   docker compose --env-file .env.docker.secret up -d
   ```

5. **Verify:**

   ```sh
   docker compose --env-file .env.docker.secret ps
   curl http://localhost:42002/health
   # Should return: {"status": "ok"}
   ```

6. **Test the API:**

   ```sh
   # Add a pet
   curl -X POST http://localhost:42002/pets \
     -H "Content-Type: application/json" \
     -d '{"name":"Luna","species":"cat","breed":"Persian","age":2}'

   # Record a vet visit
   curl -X POST http://localhost:42002/pets/1/vet-visits \
     -H "Content-Type: application/json" \
     -d '{"visit_date":"2025-03-15","notes":"Annual checkup, healthy"}'

   # Chat with AI
   curl -X POST http://localhost:42002/chat \
     -H "Content-Type: application/json" \
     -d '{"message":"When should I take Luna to the vet next?","pet_id":1}'
   ```

7. **Open Flutter client** at `http://<vm-ip>:42002/flutter`

---

## Version Plan

### Version 1 (show to TA during lab)

- ✅ Backend running with PostgreSQL
- ✅ Add pets (POST /pets)
- ✅ List pets (GET /pets)
- ✅ Record vet visits (POST /pets/{id}/vet-visits)
- ✅ View vet visit history (GET /pets/{id}/vet-visits)
- ✅ Chat with AI about pets (POST /chat) — AI receives pet context
- ✅ Flutter web client shows chat interface
- ✅ All services running via Docker Compose

### Version 2 (submit by Thursday)

- ✅ Generate reminders via AI (POST /pets/{id}/generate-reminders)
- ✅ List reminders (GET /pets/{id}/reminders)
- ✅ Deployed and accessible via VM URL
- ✅ TA feedback incorporated
- ✅ README.md with MIT license
- ✅ 5-slide presentation PDF

---

## Key Patterns to Remember

1. **Multi-stage Docker builds** — builder stage with `uv sync`, runtime stage copies `.venv` and runs as non-root
2. **Service-to-service networking** — in Docker Compose, use service names (`postgres`, `qwen-code-api`), not `localhost`
3. **Build before up** — `docker compose build` then `docker compose up -d` (not `up --build`)
4. **SQLModel** — combines SQLAlchemy + Pydantic. `SQLModel, table=True` for DB tables, `BaseModel` for request/response schemas
5. **Async everywhere** — `AsyncSession`, `async def` endpoints, `httpx.AsyncClient` for LLM calls
6. **Caddy reverse proxy** — single entry point at port 42002, routes `/pets*`, `/chat`, `/flutter*` to appropriate backends

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Backend can't connect to DB | Wrong DB_HOST in Docker | Use `postgres` (service name), not `localhost` |
| LLM returns 401 | API key not passed | Check `LLM_API_KEY` env var and `Authorization: Bearer` header |
| Flutter shows blank page | Volume not mounted in Caddy | Check `client-web-flutter:/srv/flutter:ro` in caddy volumes |
| 500 on POST /pets | DB tables not created | Check `init.sql` mounted at `/docker-entrypoint-initdb.d/` |
| Chat response is slow | LLM model is busy | 10-30s delay can be normal; check qwen-code-api logs |
| CORS error in browser | Missing CORS config | `BACKEND_CORS_ORIGINS=["*"]` in env |

---

## OpenAPI / Swagger

FastAPI auto-generates docs at `/docs` and `/openapi.json`. The TA can test all endpoints interactively via Swagger UI at `http://<vm-ip>:42002/docs`.

---

## Git Workflow for Hackathon

```sh
git checkout -b feature/cat-manager
# ... implement ...
git add .
git commit -m "feat: add cat manager backend with pet CRUD and AI chat"
git push -u origin feature/cat-manager
# Create PR, merge
```

---

## Qwen Code API Setup (REQUIRED before anything else)

The project depends on `qwen-code-api` — an OpenAI-compatible proxy that forwards requests to the real Qwen (Alibaba) API. This is a **git submodule** that runs as its own Docker service. Without it, the `/chat` endpoint cannot reach the LLM.

### Prerequisites

You need a Qwen account with API access. The free tier gives 1000 requests/day.

### Step 1: Install Qwen Code CLI

```sh
# Install Node.js and pnpm first
npm install -g pnpm
pnpm add -g @qwen-code/qwen-code
```

### Step 2: Authenticate with Qwen

```sh
qwen
# In the chat, type: /auth
# Select "Qwen OAuth" and follow the browser link to sign in
# Then type: /quit
```

This creates the credentials file at `~/.qwen/oauth_creds.json`. Verify it:

```sh
cat ~/.qwen/oauth_creds.json | jq
# Should show: { "access_token": "...", "token_type": "Bearer", "refresh_token": "...", ... }
```

### Step 3: Initialize the qwen-code-api submodule

```sh
git submodule update --init qwen-code-api
```

This downloads the `qwen-code-api/` directory (the proxy server).

### Step 4: Configure qwen-code-api secrets

```sh
cd qwen-code-api
cp .env.example .env.secret
```

Edit `qwen-code-api/.env.secret` and set:

```env
QWEN_CODE_API_KEY=my-secret-qwen-key
QWEN_CODE_API_HOST_PORT=42005
```

- `QWEN_CODE_API_KEY` — any string you choose (this is the key YOUR backend will use to authenticate)
- `QWEN_CODE_API_HOST_PORT` — the port the proxy listens on (default `42005`)

### Step 5: Start qwen-code-api

```sh
cd qwen-code-api
docker compose --env-file .env.secret up --build -d
```

Verify it's running:

```sh
docker compose --env-file .env.secret ps
# Should show a container in "Up" state

# Test the proxy:
curl http://localhost:42005/health -H "X-API-Key: my-secret-qwen-key"
# Should return 200 OK
```

### Step 6: Add qwen-code-api to the main docker-compose.yml

In the project's root `docker-compose.yml`, the `qwen-code-api` service is defined. It mounts `~/.qwen:/mnt/qwen-creds:ro` so the proxy can read the OAuth credentials:

```yaml
  qwen-code-api:
    build:
      context: ./qwen-code-api
      args:
        REGISTRY_PREFIX_DOCKER_HUB: ${REGISTRY_PREFIX_DOCKER_HUB:-}
    restart: unless-stopped
    networks:
      - cat-manager-network
    ports:
      - ${QWEN_CODE_API_HOST_ADDRESS}:${QWEN_CODE_API_HOST_PORT}:${QWEN_CODE_API_CONTAINER_PORT:-8080}
    volumes:
      - ~/.qwen:/mnt/qwen-creds:ro
    environment:
      - PORT=${QWEN_CODE_API_CONTAINER_PORT:-8080}
      - ADDRESS=${QWEN_CODE_API_CONTAINER_ADDRESS:-0.0.0.0}
      - DEFAULT_MODEL=${QWEN_CODE_API_MODEL}
      - LOG_LEVEL=${QWEN_CODE_API_LOG_LEVEL}
      - MAX_RETRIES=${QWEN_CODE_API_MAX_RETRIES}
      - RETRY_DELAY_MS=${QWEN_CODE_API_RETRY_DELAY_MS}
      - QWEN_CODE_AUTH_USE=${QWEN_CODE_API_AUTH_USE}
      - LOG_REQUESTS=${QWEN_CODE_API_LOG_REQUESTS}
      - QWEN_CODE_API_KEY=${QWEN_CODE_API_KEY:-}
```

> **IMPORTANT**: The `~/.qwen` volume mount means the qwen-code-api container reads OAuth tokens directly from your host machine. This directory must exist and contain valid `oauth_creds.json`.

### Step 7: Verify end-to-end LLM connectivity

```sh
# From the project root, query the API through the proxy:
curl http://localhost:42005/v1/chat/completions \
  -H "Authorization: Bearer my-secret-qwen-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "coder-model",
    "messages": [{"role": "user", "content": "What is 2+2?"}]
  }'
# Should return a chat completion with "4" or similar answer
```

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `oauth_creds.json` not found | Never authenticated with `qwen` CLI | Run `qwen`, type `/auth`, sign in browser |
| `port is already allocated` | Another service on 42005 | Change `QWEN_CODE_API_HOST_PORT` in `.env.secret` |
| 401 on `/v1/chat/completions` | Wrong `QWEN_CODE_API_KEY` | Make sure the key in `.env.secret` matches what your backend sends |
| `network not found` | qwen-code-api running on old network | `docker compose --env-file .env.secret down`, then `up --build -d` |
| Expired OAuth token | Token rotated / expired | Re-run `qwen`, type `/auth` to re-authenticate |

---

## What the TA Will Check

**Task 2 (plan approval):** This file + the one-sentence pitch above.

**Task 3 (Version 1):**

- Can add a pet via Swagger or Flutter
- Can record a vet visit
- Can chat with AI and get a response about the pet
- All services running via `docker compose ps`

**Task 4 (Version 2):**

- Reminder generation works
- Deployed and accessible
- README.md exists with deployment instructions
- 5-slide presentation PDF submitted
