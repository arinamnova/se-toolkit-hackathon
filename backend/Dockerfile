ARG REGISTRY_PREFIX_DOCKER_HUB
FROM ${REGISTRY_PREFIX_DOCKER_HUB}astral/uv:python3.14-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
ENV UV_NO_DEV=1
ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /app
COPY --from=workspace pyproject.toml uv.lock /app/
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
