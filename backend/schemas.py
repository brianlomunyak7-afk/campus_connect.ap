from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

NoticeCategory = Literal["Event", "Job", "Lost & Found", "General"]

# ==========================================
#               USER SCHEMAS
# ==========================================

class UserCreate(BaseModel):
    username: str = Field(min_length=1, max_length=50)
    email: EmailStr
    password: str = Field(min_length=6)


class UserResponse(BaseModel):
    """Returned to the user about themselves (includes email)."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    email: EmailStr
    created_at: datetime


class AuthorResponse(BaseModel):
    """Public author details shown on notices and comments (no email)."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    username: str


class ResetPassword(BaseModel):
    email: EmailStr
    new_password: str = Field(min_length=6)


# ==========================================
#              NOTICE SCHEMAS
# ==========================================

class NoticeCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    body: str = Field(min_length=1)
    category: NoticeCategory


class NoticeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    body: str
    category: str
    created_at: datetime
    author_id: int
    author: AuthorResponse


# ==========================================
#             COMMENT SCHEMAS
# ==========================================

class CommentCreate(BaseModel):
    content: str = Field(min_length=1)


class CommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    content: str
    notice_id: int
    created_at: datetime
    author_id: int
    author: AuthorResponse
