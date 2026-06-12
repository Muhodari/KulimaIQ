from pydantic import BaseModel, Field
from typing import Optional


class UserRegister(BaseModel):
    phone: str = Field(..., examples=["+250788000001"])
    password: str = Field(..., min_length=6)
    display_name: str = Field(..., min_length=2)


class UserLogin(BaseModel):
    phone: str
    password: str


class UserOut(BaseModel):
    id: str
    phone: str
    display_name: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut
