"""Admin 權限行為測試。conftest 設 ADMIN_EMAIL=boss@example.com。"""
import datetime

from app.config import settings
from app.routers.capsules import _is_admin


def _past():
    return (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=1)).isoformat()


def test_empty_admin_email_means_no_admin(user_a, monkeypatch):
    monkeypatch.setattr(settings, "admin_email", "")
    user_a.email = ""
    assert _is_admin(user_a) is False  # 空字串不能誤判成 admin


def test_normal_user_cannot_set_past_date(make_client, user_a):
    client = make_client(user_a)
    res = client.post("/capsules", json={
        "content": "x", "mode": "free", "open_date": _past(), "answers": [],
    })
    assert res.status_code == 400


def test_admin_can_set_past_date(make_client, admin_user):
    client = make_client(admin_user)
    res = client.post("/capsules", json={
        "content": "x", "mode": "free", "open_date": _past(), "answers": [],
    })
    assert res.status_code == 201


def test_admin_endpoint_forbidden_for_normal_user(make_client, user_a):
    client = make_client(user_a)
    assert client.post("/admin/check-notifications").status_code == 403
