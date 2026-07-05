"""/auth/verify 與 user upsert 行為。"""
import pytest
from fastapi.testclient import TestClient

from app.database import get_db
from app.main import app
from app.models.user import User
from app.routers import auth as auth_router


@pytest.fixture()
def auth_client(db, monkeypatch):
    def _get_db():
        yield db
    app.dependency_overrides[get_db] = _get_db
    yield TestClient(app), monkeypatch
    app.dependency_overrides.clear()


def test_verify_creates_user(auth_client, db):
    client, mp = auth_client
    mp.setattr(auth_router, "verify_firebase_token",
               lambda t: {"uid": "new-uid", "email": "n@example.com", "name": "New"})
    res = client.post("/auth/verify", json={"id_token": "whatever"})
    assert res.status_code == 200
    assert db.query(User).filter(User.firebase_uid == "new-uid").count() == 1
    # 再驗證一次不會重複建立，且 display_name 有同步
    mp.setattr(auth_router, "verify_firebase_token",
               lambda t: {"uid": "new-uid", "email": "n@example.com", "name": "Renamed"})
    res = client.post("/auth/verify", json={"id_token": "whatever"})
    assert res.status_code == 200
    users = db.query(User).filter(User.firebase_uid == "new-uid").all()
    assert len(users) == 1
    assert users[0].display_name == "Renamed"


def test_verify_invalid_token_returns_401(auth_client):
    client, mp = auth_client
    def boom(t):
        raise ValueError("無效的 Token")
    mp.setattr(auth_router, "verify_firebase_token", boom)
    res = client.post("/auth/verify", json={"id_token": "bad"})
    assert res.status_code == 401


def test_verify_syncs_changed_email(auth_client, db):
    client, mp = auth_client
    mp.setattr(auth_router, "verify_firebase_token",
               lambda t: {"uid": "u1", "email": "old@example.com", "name": "U"})
    assert client.post("/auth/verify", json={"id_token": "t"}).status_code == 200
    mp.setattr(auth_router, "verify_firebase_token",
               lambda t: {"uid": "u1", "email": "new@example.com", "name": "U"})
    assert client.post("/auth/verify", json={"id_token": "t"}).status_code == 200
    user = db.query(User).filter(User.firebase_uid == "u1").first()
    assert user.email == "new@example.com"
