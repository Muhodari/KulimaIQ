from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from .config import settings

_client: AsyncIOMotorClient | None = None


def get_client() -> AsyncIOMotorClient:
    global _client
    if _client is None:
        _client = AsyncIOMotorClient(
            settings.mongo_url,
            serverSelectionTimeoutMS=10_000,
        )
    return _client


def get_db() -> AsyncIOMotorDatabase:
    return get_client()[settings.mongo_db]


async def init_db() -> None:
    """Verify Atlas/local MongoDB and ensure indexes on all app collections."""
    client = get_client()
    await client.admin.command("ping")

    db = get_db()
    await db["users"].create_index("phone", unique=True)
    await db["farms"].create_index([("user_id", 1), ("created_at", -1)])
    await db["diagnoses"].create_index([("user_id", 1), ("created_at", -1)])
    await db["diagnoses"].create_index([("farm_id", 1), ("created_at", -1)])

    print(
        f"[database] Connected to MongoDB "
        f"(db={settings.mongo_db}, collections=users, farms, diagnoses)"
    )


async def check_db() -> bool:
    try:
        await get_client().admin.command("ping")
        return True
    except Exception:
        return False


async def close_db() -> None:
    global _client
    if _client is not None:
        _client.close()
        _client = None


# Collection helpers
def users_col():
    return get_db()["users"]


def farms_col():
    return get_db()["farms"]


def diagnoses_col():
    return get_db()["diagnoses"]
