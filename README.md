# 🎓 CampusConnect
> **Your Campus. Connected.**

A full-stack community notice board for university students — post events, jobs, lost items and announcements.

---

## ⚡ Run Locally in 3 Steps — No Setup Headaches!

### Step 1 — Download the Project
Click the green **"Code"** button on GitHub → **Download ZIP** → Extract it.

OR if you have Git:
```bash
git clone https://github.com/brianlomunyak7-afk/campus_connect.ap.git
cd campus_connect.ap
```

---

### Step 2 — Start the Backend
You need a running PostgreSQL database with a database named `campusconnect`.

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Create your `.env` file and fill it in:
```bash
cp .env.example .env
```

```env
DATABASE_URL=postgresql://YOUR_USER:YOUR_PASSWORD@localhost:5432/campusconnect
SECRET_KEY=a-long-random-string
```

Start the backend:
```bash
uvicorn main:app --reload --port 8001
```

✅ Backend live at → **http://127.0.0.1:8001**  
📖 API Docs at → **http://127.0.0.1:8001/docs**

---

### Step 3 — Start the Frontend
Open a **new terminal**, then:
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

✅ App opens automatically in Chrome!

---

## 🐳 OR — Run Everything With Docker (Easiest!)

Docker reads the same `backend/.env` file, so create it first (see Step 2). The `DATABASE_URL` in that file is overridden by Docker Compose to point at the bundled database, so you only need to set `SECRET_KEY`.

```bash
cp backend/.env.example backend/.env   # then set SECRET_KEY
docker compose up --build
```

Then open:
- 🌐 App API (via Nginx): **http://localhost:8080**
- 📖 API Docs (via Nginx): **http://localhost:8080/docs**
- 🔧 Direct API (no Nginx): **http://localhost:8000**

---

## 🧪 Run the Backend Tests

The tests use a real PostgreSQL database, so set `DATABASE_URL` to a **test** database (not your main one — the tests create their own rows):

```bash
cd backend
source venv/bin/activate
pip install -r requirements-dev.txt
DATABASE_URL=postgresql://YOUR_USER:YOUR_PASSWORD@localhost:5432/campusconnect_test \
SECRET_KEY=test-secret-key \
pytest
```

---

## ✨ Features

- 🔐 Register & Login with JWT Authentication
- 📢 Post notices — Events, Jobs, Lost & Found, General
- 💬 Comment on notices
- ➕ Post a notice from the app (+ button)
- 📝 Open a notice to read it, see its comments, and add one
- 🗑️ Delete your own notices
- 🚪 Log out
- 🏷️ Filter notices by category
- 🔑 Reset password from the login screen — ⚠️ no email is sent yet, see [Known Limitations](#-known-limitations)
- 🐳 Dockerized with Nginx as a reverse proxy

---

## 🌐 API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | / | ❌ | Health check |
| POST | /auth/register | ❌ | Register a new user |
| POST | /auth/login | ❌ | Login — returns a JWT `access_token` |
| POST | /auth/reset-password | ❌ | Set a new password for an email address |
| GET | /notices | ❌ | List notices (newest first), optional `?category=` filter |
| POST | /notices | ✅ | Create a notice (author is taken from the token) |
| GET | /notices/{id} | ❌ | Get a single notice |
| DELETE | /notices/{id} | ✅ | Delete a notice (author only) |
| POST | /notices/{id}/comments | ✅ | Add a comment to a notice |
| GET | /notices/{id}/comments | ❌ | List comments on a notice |

> ✅ = Requires `Authorization: Bearer <token>` header | ❌ = Public

Categories are: `Event`, `Job`, `Lost & Found`, `General`.

---

## 📁 Project Structure

```
campus_connect.ap/
├── backend/            FastAPI app
│   ├── main.py         Routes
│   ├── auth.py         Password hashing, JWT tokens, current-user dependency
│   ├── models.py       SQLAlchemy tables
│   ├── schemas.py      Pydantic request/response models
│   ├── database.py     Database engine and session
│   ├── tests/          Pytest suite (uses a real PostgreSQL database)
│   ├── Dockerfile
│   └── requirements*.txt
├── frontend/           Flutter app (web)
│   └── lib/
│       ├── main.dart
│       ├── screens/    Login, register, forgot password, home
│       ├── services/   API client and token storage
│       └── widgets/    Shared UI pieces
├── nginx/              Reverse proxy config used by Docker Compose
├── docker-compose.yml  Database + API + Nginx
└── .github/workflows/  CI: backend tests, Flutter build, Docker build
```

---

## ⚙️ Environment Variables

These live in `backend/.env` (copy from `backend/.env.example`):

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `SECRET_KEY` | Yes | Secret used to sign login tokens. Use a long random value |

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| Backend | FastAPI (Python 3.12) |
| Database | PostgreSQL 15 |
| Auth | JWT tokens (PyJWT), PBKDF2-SHA256 password hashing |
| Proxy | Nginx |
| DevOps | Docker + Docker Compose, GitHub Actions |

---

## ⚠️ Known Limitations

- **Password reset has no email step.** `POST /auth/reset-password` changes a password using only the email address, so anyone who knows an account's email can take it over. Add an emailed reset token before using this anywhere public.
- The Flutter app talks to the API at `http://127.0.0.1:8001` (see `frontend/lib/services/api_service.dart`). When using Docker, the API is at port 8080, so change `baseUrl` there.

---

## 👨‍💻 Author

**Brian** — Embu University  
HackLabs Bootcamp | Cloud/DevOps & AI Engineering Track  
🇰🇪 Kenya

---

## 📄 License
MIT — free to use and modify!
