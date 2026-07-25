from typing import List
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import models
import schemas
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="CampusConnect API",
    description="Your Campus. Connected.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root(db: Session = Depends(get_db)):
    test_user = db.query(models.User).filter(models.User.id == 1).first()
    if not test_user:
        fallback_user = models.User(
            id=1,
            username="TestAdmin",
            email="admin@campusconnect.com",
            hashed_password="hashed_password123"
        )
        db.add(fallback_user)
        db.commit()
    return {"message": "Welcome to CampusConnect API!", "status": "running"}

# --- USER ENDPOINTS ---

@app.post("/users/", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_username = db.query(models.User).filter(models.User.username == user.username).first()
    if db_username:
        raise HTTPException(status_code=400, detail="Username already taken")

    # For now, we store a simple hashed password placeholder. We'll swap in real bcrypt hashing shortly!
    fake_hashed_password = f"hashed_{user.password}"
    new_user = models.User(
        username=user.username,
        email=user.email,
        hashed_password=fake_hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.get("/users/", response_model=List[schemas.UserResponse])
def get_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    return db.query(models.User).offset(skip).limit(limit).all()


# --- NOTICES ENDPOINTS ---

@app.post("/notices/", response_model=schemas.NoticeResponse, status_code=status.HTTP_201_CREATED)
def create_notice(notice: schemas.NoticeCreate, author_id: int, db: Session = Depends(get_db)):
    # Check if author exists
    author = db.query(models.User).filter(models.User.id == author_id).first()
    if not author:
        raise HTTPException(status_code=404, detail="Author/User not found")
        
    new_notice = models.Notice(
        title=notice.title,
        body=notice.body,
        category=notice.category,
        author_id=author_id
    )
    db.add(new_notice)
    db.commit()
    db.refresh(new_notice)
    return new_notice

@app.get("/notices/", response_model=List[schemas.NoticeResponse])
def list_notices(category: str = None, db: Session = Depends(get_db)):
    query = db.query(models.Notice)
    if category:
        query = query.filter(models.Notice.category == category)
    return query.all()


# --- COMMENTS ENDPOINTS ---

@app.post("/comments/", response_model=schemas.CommentResponse, status_code=status.HTTP_201_CREATED)
def create_comment(comment: schemas.CommentCreate, author_id: int, db: Session = Depends(get_db)):
    # Verify notice exists
    notice = db.query(models.Notice).filter(models.Notice.id == comment.notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    
    # Verify user exists
    user = db.query(models.User).filter(models.User.id == author_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_comment = models.Comment(
        content=comment.content,
        notice_id=comment.notice_id,
        author_id=author_id
    )
    db.add(new_comment)
    db.commit()
    db.refresh(new_comment)
    return new_comment

@app.post("/auth/reset-password")
def reset_password(data: schemas.ResetPassword, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Email not found")
    user.hashed_password = hash_password(data.new_password)
    db.commit()
    return {"message": "Password reset successful"}