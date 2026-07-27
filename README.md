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
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Create your `.env` file:
```bash
cp .env.example .env
```

Edit `.env` and fill in your database details:
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
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

✅ App opens automatically in Chrome!

---

## 🐳 OR — Run Everything With Docker (Easiest!)

```bash
docker compose up --build
```

Then open:
- 🌐 App API: **http://localhost**
- 📖 API Docs: **http://localhost/docs**

---

## ✨ Features

- 🔐 Register & Login with JWT Authentication
- 📢 Post notices — Events, Jobs, Lost & Found, General
- 💬 Comment on notices
- 🏷️ Filter notices by category
- 🎨 Animated UI — floating particles + animated lamp mascot
- 🔑 Forgot password — reset via email
- 🐳 Fully Dockerized — production ready

---

## 🌐 API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | / | ❌ | Health check |
| POST | /auth/register | ❌ | Register user |
| POST | /auth/login | ❌ | Login + get token |
| POST | /auth/reset-password | ❌ | Reset password |
| GET | /notices | ❌ | Get all notices |
| POST | /notices | ✅ | Create notice |
| GET | /notices/{id} | ❌ | Get single notice |
| DELETE | /notices/{id} | ✅ | Delete notice |
| POST | /notices/{id}/comments | ✅ | Add comment |
| GET | /notices/{id}/comments | ❌ | Get comments |

> ✅ = Requires JWT Bearer Token | ❌ = Public

---

## 📁 Project Structure
---

## ⚙️ Environment Variables

Copy the example file:
```bash
cp backend/.env.example backend/.env
```

Then edit `backend/.env`:
```env
DATABASE_URL=postgresql://YOUR_USER:YOUR_PASSWORD@localhost:5432/campusconnect
SECRET_KEY=your-super-secret-key-here
```

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| Backend | FastAPI (Python) |
| Database | PostgreSQL |
| Auth | JWT Tokens |
| Proxy | Nginx |
| DevOps | Docker + Docker Compose |

---

## 👨‍💻 Author

**Brian** — Embu University  
HackLabs Bootcamp | Cloud/DevOps & AI Engineering Track  
🇰🇪 Kenya

---

## 📄 License
MIT — free to use and modify!
