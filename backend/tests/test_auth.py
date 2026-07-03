"""Unit tests for password hashing and JWT helpers."""

import pytest
from fastapi import HTTPException
from jose import jwt

from app.auth import (
    create_access_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.config import settings


def test_hash_and_verify_password():
    hashed = hash_password("farmer123")
    assert hashed != "farmer123"
    assert verify_password("farmer123", hashed)
    assert not verify_password("wrong-password", hashed)


def test_create_and_decode_access_token():
    token = create_access_token({"sub": "user-123"})
    payload = decode_token(token)
    assert payload["sub"] == "user-123"


def test_decode_invalid_token_raises():
    with pytest.raises(HTTPException) as exc:
        decode_token("not-a-valid-token")
    assert exc.value.status_code == 401


def test_expired_token_rejected():
    token = jwt.encode(
        {"sub": "user-123", "exp": 1},
        settings.secret_key,
        algorithm=settings.algorithm,
    )
    with pytest.raises(HTTPException):
        decode_token(token)
