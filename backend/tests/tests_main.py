from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "running"

def test_get_notices():
    response = client.get("/notices")
    assert response.status_code == 200

def test_register_missing_fields():
    response = client.post("/auth/register", json={})
    assert response.status_code == 422

def test_login_wrong_credentials():
    response = client.post("/auth/login", json={
        "email": "wrong@test.com",
        "password": "wrongpassword"
    })
    assert response.status_code == 401
