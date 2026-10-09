import uuid

import pytest
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)

PASSWORD = "secret123"


def _unique_user(prefix="user"):
    tag = uuid.uuid4().hex[:10]
    return {"username": f"{prefix}_{tag}", "email": f"{prefix}_{tag}@test.com", "password": PASSWORD}


def _register_and_login(user=None):
    user = user or _unique_user()
    assert client.post("/auth/register", json=user).status_code == 201
    response = client.post("/auth/login", json={"email": user["email"], "password": user["password"]})
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


@pytest.fixture
def auth_headers():
    return _register_and_login()


def _create_notice(headers, category="Event"):
    response = client.post(
        "/notices",
        json={"title": "Hackathon", "body": "Bring a laptop", "category": category},
        headers=headers,
    )
    assert response.status_code == 201
    return response.json()


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "running"


def test_register_returns_user_without_password():
    user = _unique_user()
    response = client.post("/auth/register", json=user)
    assert response.status_code == 201
    body = response.json()
    assert body["username"] == user["username"]
    assert body["email"] == user["email"]
    assert "password" not in body and "hashed_password" not in body


def test_register_duplicate_email_rejected():
    user = _unique_user()
    assert client.post("/auth/register", json=user).status_code == 201
    user["username"] = f"other_{uuid.uuid4().hex[:8]}"
    response = client.post("/auth/register", json=user)
    assert response.status_code == 400
    assert response.json()["detail"] == "Email already registered"


def test_register_missing_fields():
    response = client.post("/auth/register", json={})
    assert response.status_code == 422


def test_register_short_password_rejected():
    user = _unique_user()
    user["password"] = "123"
    assert client.post("/auth/register", json=user).status_code == 422


def test_login_success_returns_token_and_username():
    user = _unique_user()
    client.post("/auth/register", json=user)
    response = client.post("/auth/login", json={"email": user["email"], "password": user["password"]})
    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["username"] == user["username"]
    assert body["access_token"]


def test_login_wrong_credentials():
    response = client.post("/auth/login", json={
        "email": "wrong@test.com",
        "password": "wrongpassword"
    })
    assert response.status_code == 401


def test_login_wrong_password():
    user = _unique_user()
    client.post("/auth/register", json=user)
    response = client.post("/auth/login", json={"email": user["email"], "password": "not-the-password"})
    assert response.status_code == 401


def test_reset_password_then_login_with_new_password():
    user = _unique_user()
    client.post("/auth/register", json=user)
    response = client.post("/auth/reset-password", json={"email": user["email"], "new_password": "brandnew1"})
    assert response.status_code == 200
    assert client.post("/auth/login", json={"email": user["email"], "password": "brandnew1"}).status_code == 200
    assert client.post("/auth/login", json={"email": user["email"], "password": PASSWORD}).status_code == 401


def test_reset_password_unknown_email():
    response = client.post("/auth/reset-password", json={"email": "nobody@test.com", "new_password": "brandnew1"})
    assert response.status_code == 404


def test_get_notices_is_public():
    response = client.get("/notices")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_create_notice_requires_auth():
    response = client.post("/notices", json={"title": "t", "body": "b", "category": "Event"})
    assert response.status_code in (401, 403)


def test_create_notice_with_invalid_token():
    response = client.post(
        "/notices",
        json={"title": "t", "body": "b", "category": "Event"},
        headers={"Authorization": "Bearer not-a-real-token"},
    )
    assert response.status_code == 401


def test_create_and_fetch_notice(auth_headers):
    notice = _create_notice(auth_headers, category="Lost & Found")
    assert notice["category"] == "Lost & Found"
    assert notice["author"]["username"]
    assert "email" not in notice["author"]

    fetched = client.get(f"/notices/{notice['id']}")
    assert fetched.status_code == 200
    assert fetched.json()["id"] == notice["id"]


def test_filter_notices_by_category(auth_headers):
    notice = _create_notice(auth_headers, category="Job")
    response = client.get("/notices", params={"category": "Job"})
    assert response.status_code == 200
    ids = [n["id"] for n in response.json()]
    assert notice["id"] in ids
    assert all(n["category"] == "Job" for n in response.json())


def test_invalid_category_rejected(auth_headers):
    response = client.post(
        "/notices",
        json={"title": "t", "body": "b", "category": "Gossip"},
        headers=auth_headers,
    )
    assert response.status_code == 422


def test_get_missing_notice_returns_404():
    assert client.get("/notices/999999999").status_code == 404


def test_only_author_can_delete_notice(auth_headers):
    notice = _create_notice(auth_headers)
    other_headers = _register_and_login()

    assert client.delete(f"/notices/{notice['id']}", headers=other_headers).status_code == 403
    assert client.delete(f"/notices/{notice['id']}", headers=auth_headers).status_code == 204
    assert client.get(f"/notices/{notice['id']}").status_code == 404


def test_add_and_list_comments(auth_headers):
    notice = _create_notice(auth_headers)
    response = client.post(
        f"/notices/{notice['id']}/comments",
        json={"content": "I'm in!"},
        headers=auth_headers,
    )
    assert response.status_code == 201
    comment = response.json()
    assert comment["content"] == "I'm in!"
    assert comment["notice_id"] == notice["id"]
    assert "email" not in comment["author"]

    listed = client.get(f"/notices/{notice['id']}/comments")
    assert listed.status_code == 200
    assert [c["id"] for c in listed.json()] == [comment["id"]]


def test_comment_on_missing_notice_returns_404(auth_headers):
    response = client.post("/notices/999999999/comments", json={"content": "hi"}, headers=auth_headers)
    assert response.status_code == 404


def test_comments_require_auth(auth_headers):
    notice = _create_notice(auth_headers)
    response = client.post(f"/notices/{notice['id']}/comments", json={"content": "hi"})
    assert response.status_code in (401, 403)


def test_health_reports_database_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "ok"}


def test_me_returns_current_user(auth_headers):
    response = client.get("/auth/me", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["username"]
    assert "hashed_password" not in response.json()


def test_me_requires_valid_token():
    assert client.get("/auth/me").status_code in (401, 403)


def test_notices_pagination(auth_headers):
    for i in range(3):
        _create_notice(auth_headers, category="General")
    first = client.get("/notices", params={"category": "General", "limit": 2, "offset": 0}).json()
    second = client.get("/notices", params={"category": "General", "limit": 2, "offset": 2}).json()
    assert len(first) == 2
    assert len(second) >= 1
    assert not {n["id"] for n in first} & {n["id"] for n in second}


def test_pagination_limits_are_validated():
    assert client.get("/notices", params={"limit": 0}).status_code == 422
    assert client.get("/notices", params={"limit": 101}).status_code == 422
    assert client.get("/notices", params={"offset": -1}).status_code == 422


def test_author_can_edit_notice(auth_headers):
    notice = _create_notice(auth_headers, category="Event")
    response = client.patch(
        f"/notices/{notice['id']}",
        json={"title": "Updated title", "category": "Job"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["title"] == "Updated title"
    assert body["category"] == "Job"
    assert body["body"] == "Bring a laptop"


def test_other_user_cannot_edit_notice(auth_headers):
    notice = _create_notice(auth_headers)
    other_headers = _register_and_login()
    response = client.patch(f"/notices/{notice['id']}", json={"title": "hijack"}, headers=other_headers)
    assert response.status_code == 403


def test_edit_rejects_invalid_category(auth_headers):
    notice = _create_notice(auth_headers)
    response = client.patch(f"/notices/{notice['id']}", json={"category": "Gossip"}, headers=auth_headers)
    assert response.status_code == 422


def test_author_can_delete_own_comment(auth_headers):
    notice = _create_notice(auth_headers)
    comment = client.post(
        f"/notices/{notice['id']}/comments", json={"content": "bye"}, headers=auth_headers
    ).json()
    assert client.delete(f"/comments/{comment['id']}", headers=auth_headers).status_code == 204
    assert client.get(f"/notices/{notice['id']}/comments").json() == []


def test_other_user_cannot_delete_comment(auth_headers):
    notice = _create_notice(auth_headers)
    comment = client.post(
        f"/notices/{notice['id']}/comments", json={"content": "mine"}, headers=auth_headers
    ).json()
    other_headers = _register_and_login()
    assert client.delete(f"/comments/{comment['id']}", headers=other_headers).status_code == 403


def test_delete_missing_comment_returns_404(auth_headers):
    assert client.delete("/comments/999999999", headers=auth_headers).status_code == 404


def test_deleting_notice_removes_its_comments(auth_headers):
    notice = _create_notice(auth_headers)
    client.post(f"/notices/{notice['id']}/comments", json={"content": "x"}, headers=auth_headers)
    assert client.delete(f"/notices/{notice['id']}", headers=auth_headers).status_code == 204
    assert client.get(f"/notices/{notice['id']}/comments").status_code == 404
