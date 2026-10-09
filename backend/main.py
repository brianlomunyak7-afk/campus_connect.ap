from typing import List, Optional

from fastapi import Depends, FastAPI, HTTPException, Response, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

import models
import schemas
from auth import create_access_token, get_current_user, hash_password, verify_password
from config import get_settings
from database import get_db

app = FastAPI(
    title="CampusConnect API",
    description="Your Campus. Connected.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(get_settings().cors_origins),
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {"message": "Welcome to CampusConnect API!", "status": "running"}


# --- AUTH ENDPOINTS ---

@app.post("/auth/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    new_user = models.User(
        username=user.username,
        email=user.email,
        hashed_password=hash_password(user.password),
    )
    db.add(new_user)
    try:
        db.commit()
    except IntegrityError:
        # Lost a race with a concurrent registration for the same email/username
        db.rollback()
        raise HTTPException(status_code=400, detail="Email or username already in use")
    db.refresh(new_user)
    return new_user


@app.post("/auth/login", response_model=schemas.TokenResponse)
def login(credentials: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == credentials.email).first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Wrong email or password")
    return schemas.TokenResponse(
        access_token=create_access_token(user.id),
        username=user.username,
    )


@app.post("/auth/reset-password")
def reset_password(data: schemas.ResetPassword, db: Session = Depends(get_db)):
    # NOTE: no email is sent yet, so this resets by email address alone.
    # Anyone who knows an account's email can change its password. Add an emailed token before production.
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Email not found")
    user.hashed_password = hash_password(data.new_password)
    db.commit()
    return {"message": "Password reset successful"}


# --- NOTICES ENDPOINTS ---

@app.get("/notices", response_model=List[schemas.NoticeResponse])
def list_notices(category: Optional[schemas.NoticeCategory] = None, db: Session = Depends(get_db)):
    query = db.query(models.Notice)
    if category:
        query = query.filter(models.Notice.category == category)
    return query.order_by(models.Notice.created_at.desc(), models.Notice.id.desc()).all()


@app.post("/notices", response_model=schemas.NoticeResponse, status_code=status.HTTP_201_CREATED)
def create_notice(
    notice: schemas.NoticeCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    new_notice = models.Notice(
        title=notice.title,
        body=notice.body,
        category=notice.category,
        author_id=current_user.id,
    )
    db.add(new_notice)
    db.commit()
    db.refresh(new_notice)
    return new_notice


def _get_notice_or_404(notice_id: int, db: Session) -> models.Notice:
    notice = db.query(models.Notice).filter(models.Notice.id == notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    return notice


@app.get("/notices/{notice_id}", response_model=schemas.NoticeResponse)
def get_notice(notice_id: int, db: Session = Depends(get_db)):
    return _get_notice_or_404(notice_id, db)


@app.delete("/notices/{notice_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_notice(
    notice_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notice = _get_notice_or_404(notice_id, db)
    if notice.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only delete your own notices")
    db.delete(notice)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# --- COMMENTS ENDPOINTS ---

@app.post("/notices/{notice_id}/comments", response_model=schemas.CommentResponse, status_code=status.HTTP_201_CREATED)
def create_comment(
    notice_id: int,
    comment: schemas.CommentCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _get_notice_or_404(notice_id, db)
    new_comment = models.Comment(
        content=comment.content,
        notice_id=notice_id,
        author_id=current_user.id,
    )
    db.add(new_comment)
    db.commit()
    db.refresh(new_comment)
    return new_comment


@app.get("/notices/{notice_id}/comments", response_model=List[schemas.CommentResponse])
def list_comments(notice_id: int, db: Session = Depends(get_db)):
    _get_notice_or_404(notice_id, db)
    return (
        db.query(models.Comment)
        .filter(models.Comment.notice_id == notice_id)
        .order_by(models.Comment.created_at.asc(), models.Comment.id.asc())
        .all()
    )
