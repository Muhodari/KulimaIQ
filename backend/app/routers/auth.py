import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status

from ..auth import create_access_token, hash_password, verify_password
from ..database import users_col
from ..models.user import TokenOut, UserLogin, UserOut, UserRegister

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenOut, status_code=201)
async def register(body: UserRegister):
    existing = await users_col().find_one({"phone": body.phone})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Phone number already registered",
        )
    user_id = str(uuid.uuid4())
    doc = {
        "_id": user_id,
        "phone": body.phone,
        "password_hash": hash_password(body.password),
        "display_name": body.display_name,
        "created_at": datetime.now(timezone.utc),
    }
    await users_col().insert_one(doc)
    token = create_access_token({"sub": user_id})
    return TokenOut(
        access_token=token,
        user=UserOut(id=user_id, phone=body.phone, display_name=body.display_name),
    )


@router.post("/login", response_model=TokenOut)
async def login(body: UserLogin):
    user = await users_col().find_one({"phone": body.phone})
    if not user or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone or password",
        )
    token = create_access_token({"sub": user["_id"]})
    return TokenOut(
        access_token=token,
        user=UserOut(
            id=user["_id"],
            phone=user["phone"],
            display_name=user["display_name"],
        ),
    )
