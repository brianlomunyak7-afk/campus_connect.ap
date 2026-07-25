from datetime import datetime
from pydantic import BaseModel, EmailStr

# ==========================================
#               USER SCHEMAS
# ==========================================

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ==========================================
#              NOTICE SCHEMAS
# ==========================================

class NoticeBase(BaseModel):
    title: str
    body: str
    category: str

class NoticeCreate(NoticeBase):
    pass

class NoticeResponse(NoticeBase):
    id: int
    created_at: datetime
    author_id: int
    author: UserResponse  # Nests the creator's details inside the notice

    class Config:
        from_attributes = True


# ==========================================
#             COMMENT SCHEMAS
# ==========================================

class CommentBase(BaseModel):
    body: str
    notice_id: int

class CommentCreate(CommentBase):
    pass

class CommentResponse(CommentBase):
    id: int
    created_at: datetime
    author_id: int
    author: UserResponse  # Nests the comment author's details

    class Config:
        from_attributes = True

class ResetPassword(BaseModel):
    email: str
    new_password: str