"""Redis caching service for ElastiCache integration."""

import json
import logging
from typing import Any, Optional
import redis.asyncio as redis
from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_redis: Optional[redis.Redis] = None


async def connect_to_redis() -> None:
    """Initialize Redis connection."""
    global _redis
    try:
        _redis = redis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )
        await _redis.ping()
        logger.info("✅ Connected to Redis")
    except Exception as e:
        logger.warning(f"⚠️ Redis connection failed: {e}. Caching disabled.")
        _redis = None


async def close_redis_connection() -> None:
    """Close Redis connection."""
    global _redis
    if _redis:
        await _redis.close()
        logger.info("🔌 Redis connection closed")


async def get_cached(key: str) -> Optional[Any]:
    """Get a value from cache."""
    if _redis is None:
        return None
    try:
        value = await _redis.get(key)
        if value:
            return json.loads(value)
        return None
    except Exception as e:
        logger.warning(f"Cache get error: {e}")
        return None


async def set_cached(key: str, value: Any, ttl: int | None = None) -> None:
    """Set a value in cache."""
    if _redis is None:
        return
    try:
        ttl = ttl or settings.CACHE_TTL
        await _redis.set(key, json.dumps(value, default=str), ex=ttl)
    except Exception as e:
        logger.warning(f"Cache set error: {e}")


async def delete_cached(key: str) -> None:
    """Delete a value from cache."""
    if _redis is None:
        return
    try:
        await _redis.delete(key)
    except Exception as e:
        logger.warning(f"Cache delete error: {e}")


async def invalidate_pattern(pattern: str) -> None:
    """Delete all keys matching a pattern."""
    if _redis is None:
        return
    try:
        async for key in _redis.scan_iter(match=pattern):
            await _redis.delete(key)
    except Exception as e:
        logger.warning(f"Cache invalidation error: {e}")
