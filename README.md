# 🎓 CampusConnect
> **Your Campus. Connected.**

A full-stack community notice board for university students — post events, jobs, lost items and announcements, discuss them in comments.

---

## ⚡ Run Locally in 3 Steps

### Step 1 — Download the Project
```bash
git clone https://github.com/brianlomunyak7-afk/campus_connect.ap.git
cd campus_connect.ap
```

### Step 2 — Start the Backend
You need PostgreSQL running with a database named `campusconnect`.

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # then set DATABASE_URL and SECRET_KEY
alembic upgrade head          # creates the tables
uvicorn main:app --reload --port 8001
```

✅ Backend live at → **http://127.0.0.1:8001**
📖 API docs at → **http://127.0.0.1:8001/docs**

### Step 3 — Start the Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 🐳 Or Run Everything With Docker

```bash
cp backend/.env.example backend/.env    # set SECRET_KEY
docker compose up --build
```

The database, API (with migrations applied on start) and Nginx all come up together.

- 🌐 App API via Nginx: **http://localhost:8080**
- 📖 API docs via Nginx: **http://localhost:8080/docs**
- 🔧 Direct API: **http://localhost:8000**
- 🩺 Health check: **http://localhost:8080/health**

To run more API workers, set `WEB_CONCURRENCY` in `docker-compose.yml` (default 2).

---

## 🧪 Run the Tests

The tests use a real PostgreSQL database and create their own rows, so point them at a **test** database:

```bash
cd backend
source venv/bin/activate
pip install -r requirements-dev.txt
DATABASE_URL=postgresql://YOUR_USER:YOUR_PASSWORD@localhost:5432/campusconnect_test \
SECRET_KEY=test-secret-key \
pytest
```

The test session applies the Alembic migrations before running.

---

## ✨ Features

- 🔐 Register, login and log out with JWT tokens
- 👤 Current user endpoint (`/auth/me`)
- 📢 Post notices in four categories: Event, Job, Lost & Found, General
- ✏️ Edit and 🗑️ delete your own notices
- 💬 Comment on notices and delete your own comments
- 🏷️ Filter notices by category
- 📄 Paginated notice and comment lists ("Load more" in the app)
- 🔑 Reset password from the login screen — ⚠️ no email is sent yet, see [Known Limitations](#️-known-limitations)
- 🐳 Dockerized: PostgreSQL, API and Nginx, with health checks and a non-root API container

---

## 🌐 API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | / | ❌ | Liveness check |
| GET | /health | ❌ | Checks the database connection (503 if down) |
| POST | /auth/register | ❌ | Register a new user |
| POST | /auth/login | ❌ | Login — returns a JWT `access_token` |
| GET | /auth/me | ✅ | The logged-in user |
| POST | /auth/reset-password | ❌ | Set a new password for an email address |
| GET | /notices | ❌ | List notices, newest first. Query: `category`, `limit` (1–100, default 20), `offset` |
| POST | /notices | ✅ | Create a notice (author comes from the token) |
| GET | /notices/{id} | ❌ | Get one notice |
| PATCH | /notices/{id} | ✅ | Edit your notice (author only) |
| DELETE | /notices/{id} | ✅ | Delete your notice and its comments (author only) |
| GET | /notices/{id}/comments | ❌ | List comments, oldest first. Query: `limit` (default 50), `offset` |
| POST | /notices/{id}/comments | ✅ | Add a comment |
| DELETE | /comments/{id} | ✅ | Delete your comment (author only) |

> ✅ = Requires `Authorization: Bearer <token>` header | ❌ = Public

Interactive docs at `/docs` list the request and response shapes.

---

## 📁 Project Structure

```
campus_connect.ap/
├── backend/                  FastAPI app
│   ├── main.py               Routes
│   ├── auth.py               Password hashing, JWT tokens, current-user dependency
│   ├── config.py             Settings read from environment variables
│   ├── database.py           Engine (with connection pool) and sessions
│   ├── models.py             SQLAlchemy tables
│   ├── schemas.py            Request and response models
│   ├── migrations/           Alembic migrations
│   ├── tests/                Pytest suite (real PostgreSQL)
│   ├── Dockerfile
│   └── requirements*.txt
├── frontend/                 Flutter app (web)
│   └── lib/
│       ├── main.dart
│       ├── screens/          Login, register, forgot password, home, notice detail, create/edit notice
│       ├── services/         API client and token storage
│       └── widgets/          Shared UI pieces
├── nginx/                    Reverse proxy config used by Docker Compose
├── docker-compose.yml        Database + API + Nginx
└── .github/workflows/        CI: backend tests, Flutter build, Docker build
```

---

## ⚙️ Configuration

Set these in `backend/.env` (copy from `backend/.env.example`):

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | local Postgres | PostgreSQL connection string |
| `SECRET_KEY` | Yes | — | Signs login tokens. Use a long random value |
| `CORS_ORIGINS` | No | `*` | Comma-separated list of allowed browser origins |
| `TOKEN_EXPIRE_MINUTES` | No | `10080` (7 days) | Login token lifetime |
| `DB_POOL_SIZE` | No | `10` | Database connections kept open per process |
| `DB_MAX_OVERFLOW` | No | `20` | Extra connections allowed under load |

Docker Compose overrides `DATABASE_URL` to point at the bundled database and sets `WEB_CONCURRENCY`.

---

## 🗄️ Database Migrations

The schema is managed by Alembic. The API container runs `alembic upgrade head` on start.

```bash
cd backend
alembic upgrade head                               # apply all migrations
alembic revision --autogenerate -m "describe change"   # after editing models.py
```

If you have a database created by an older version of this project, drop it and let the migrations create it, or run `alembic stamp head` only if its tables already match the current models.

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| Backend | FastAPI (Python 3.12), SQLAlchemy 2, Alembic |
| Database | PostgreSQL 15 |
| Auth | JWT (PyJWT), PBKDF2-SHA256 password hashing |
| Proxy | Nginx |
| DevOps | Docker, Docker Compose, GitHub Actions |

---

## ⚠️ Known Limitations

- **Password reset has no email step.** `POST /auth/reset-password` changes a password using only the email address, so anyone who knows an account's email can take it over. Add an emailed reset token before using this anywhere public.
- **No rate limiting** on login or registration. Put Nginx `limit_req` or an API gateway in front before opening it to the internet.
- The Flutter app talks to the API at `http://127.0.0.1:8001` (see `frontend/lib/services/api_service.dart`). When using Docker, the API is at port 8080, so change `baseUrl` there.
- The home screen background is a static gradient, not an animation.

---

## 👨‍💻 Author

**Brian** — Embu University
HackLabs Bootcamp | Cloud/DevOps & AI Engineering Track
🇰🇪 Kenya

---

## 📄 License
MIT — free to use and modify!
