"""FastAPI application entry point with logging, CORS, and lifecycle management."""

import json
import logging
import sys
import time
import uuid
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import (
    Counter,
    Histogram,
    generate_latest,
    CONTENT_TYPE_LATEST,
)
from fastapi.responses import Response

from config import get_settings
from db.mongo import connect_to_mongo, close_mongo_connection
from services.cache_service import connect_to_redis, close_redis_connection
from routers.chat import router as chat_router

settings = get_settings()

# ──────────────────────── Structured Logging ────────────────────────


class JSONFormatter(logging.Formatter):
    """JSON formatter for structured CloudWatch-compatible logging."""

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        if record.exc_info and record.exc_info[0]:
            log_data["exception"] = self.formatException(record.exc_info)
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        return json.dumps(log_data)


def setup_logging():
    """Configure JSON structured logging."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO))

    # Reduce noise from third-party libraries
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("motor").setLevel(logging.WARNING)


# ──────────────────────── Prometheus Metrics ────────────────────────

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)
CHAT_REQUESTS = Counter(
    "chat_requests_total",
    "Total chat requests",
    ["status"],
)
FILE_UPLOADS = Counter(
    "file_uploads_total",
    "Total file uploads",
    ["content_type"],
)
ACTIVE_CONVERSATIONS = Counter(
    "conversations_created_total",
    "Total conversations created",
)

# ──────────────────────── App Lifecycle ────────────────────────

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    setup_logging()
    logger.info(f"🚀 Starting {settings.APP_NAME} v{settings.APP_VERSION}")

    await connect_to_mongo()
    await connect_to_redis()

    yield

    await close_redis_connection()
    await close_mongo_connection()
    logger.info("👋 Application shutdown complete")


# ──────────────────────── FastAPI App ────────────────────────

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

# CORS
origins = [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ──────────────────────── Middleware ────────────────────────


@app.middleware("http")
async def logging_and_metrics_middleware(request: Request, call_next):
    """Log every request and track metrics."""
    request_id = str(uuid.uuid4())[:8]
    start_time = time.time()

    # Inject request_id into logs
    logger_adapter = logging.LoggerAdapter(logger, {"request_id": request_id})

    logger_adapter.info(
        f"→ {request.method} {request.url.path} "
        f"client={request.client.host if request.client else 'unknown'}"
    )

    response = await call_next(request)

    duration = time.time() - start_time
    status = response.status_code

    logger_adapter.info(
        f"← {request.method} {request.url.path} "
        f"status={status} duration={duration:.3f}s"
    )

    # Update Prometheus metrics
    endpoint = request.url.path
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=endpoint,
        status=str(status),
    ).inc()
    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=endpoint,
    ).observe(duration)

    # Add headers
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Response-Time"] = f"{duration:.3f}s"

    return response


# ──────────────────────── Routes ────────────────────────

app.include_router(chat_router)


@app.get("/api/health")
async def health_check():
    """Health check endpoint for ALB."""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/api/metrics")
async def metrics():
    """Prometheus metrics endpoint for Grafana."""
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST,
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
