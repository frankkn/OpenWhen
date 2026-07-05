"""Email 通知：收件人驗證 + HTML 注入防護。"""
import datetime

import httpx
import pytest

from app.config import settings
from app.services import email_service


def _future():
    return (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=30)).isoformat()


def test_invalid_notification_email_rejected(client):
    res = client.post("/capsules", json={
        "content": "x", "mode": "free", "open_date": _future(),
        "notification_email": "not-an-email",
    })
    assert res.status_code == 422


def test_valid_notification_email_accepted(client):
    res = client.post("/capsules", json={
        "content": "x", "mode": "free", "open_date": _future(),
        "notification_email": "me@example.com",
    })
    assert res.status_code == 201


def test_title_is_html_escaped_in_email(monkeypatch):
    monkeypatch.setattr(settings, "brevo_api_key", "test")
    monkeypatch.setattr(settings, "mail_from_email", "noreply@example.com")

    captured = {}

    def fake_post(url, json=None, headers=None, timeout=None):
        captured["payload"] = json
        req = httpx.Request("POST", url)
        return httpx.Response(201, request=req)

    monkeypatch.setattr(httpx, "post", fake_post)

    evil = '<img src=x onerror="alert(1)">'
    email_service.send_capsule_ready_email(
        to="victim@example.com",
        capsule_title=evil,
        open_date=datetime.datetime.now(datetime.timezone.utc),
        created_at_str="2026 年 01 月 01 日",
    )
    html = captured["payload"]["htmlContent"]
    assert evil not in html
    assert "&lt;img" in html
