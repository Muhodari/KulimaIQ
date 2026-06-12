from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from .config import settings

_client: AsyncIOMotorClient | None = None


def get_client() -> AsyncIOMotorClient:
    global _client
    if _client is None:
        _client = AsyncIOMotorClient(settings.mongo_url)
    return _client


def get_db() -> AsyncIOMotorDatabase:
    return get_client()[settings.mongo_db]


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
