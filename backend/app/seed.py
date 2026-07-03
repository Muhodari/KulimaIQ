"""Seed data required for local development and demo flows."""

import uuid
from datetime import datetime, timezone

from .auth import hash_password
from .database import users_col

DEMO_PHONE = "0780000000"
DEMO_PASSWORD = "farmer123"
DEMO_NAME = "Demo Farmer"


async def ensure_demo_user() -> None:
    """Create the demo farmer account if it does not exist yet."""
    existing = await users_col().find_one({"phone": DEMO_PHONE})
    if existing is not None:
        return

    user_id = str(uuid.uuid4())
    await users_col().insert_one(
        {
            "_id": user_id,
            "phone": DEMO_PHONE,
            "password_hash": hash_password(DEMO_PASSWORD),
            "display_name": DEMO_NAME,
            "created_at": datetime.now(timezone.utc),
        }
    )
    print(f"[seed] Created demo user {DEMO_PHONE} (id={user_id})")
