"""Pytest fixtures：sqlite in-memory DB + 繞過 Firebase 的測試 client。"""
import os
import sys

# 必須在 import app 之前設定（env var 優先於 .env）
os.environ["DATABASE_URL"] = "sqlite://"
os.environ["FIREBASE_PROJECT_ID"] = "test-project"
os.environ["GEMINI_API_KEY"] = "test-key"
os.environ["ADMIN_EMAIL"] = "boss@example.com"
os.environ["BREVO_API_KEY"] = ""
os.environ["MAIL_FROM_EMAIL"] = ""

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.dependencies import get_current_user
from app.limiter import limiter
from app.main import app
from app.models.user import User

engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

limiter.enabled = False  # 測試中不做 rate limit


@pytest.fixture()
def db():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def user_a(db):
    u = User(firebase_uid="uid-a", email="a@example.com", display_name="A")
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


@pytest.fixture()
def user_b(db):
    u = User(firebase_uid="uid-b", email="b@example.com", display_name="B")
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


@pytest.fixture()
def admin_user(db):
    u = User(firebase_uid="uid-admin", email="boss@example.com", display_name="Boss")
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


@pytest.fixture()
def make_client(db):
    """回傳 factory：以指定 user 身分建立 TestClient。"""
    def _get_db():
        yield db

    def _make(user: User) -> TestClient:
        app.dependency_overrides[get_db] = _get_db
        app.dependency_overrides[get_current_user] = lambda: user
        return TestClient(app)
    yield _make
    app.dependency_overrides.clear()


@pytest.fixture()
def client(make_client, user_a):
    return make_client(user_a)
