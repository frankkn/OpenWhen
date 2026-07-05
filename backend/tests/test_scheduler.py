"""排程通知：成功、暫時失敗（重試）、永久失敗（不重試）。"""
import datetime

import httpx
import pytest

from app import scheduler as sched
from app.config import settings
from app.models.capsule import Capsule, CapsuleMode, CapsuleStatus


@pytest.fixture()
def due_capsule(db, user_a):
    c = Capsule(
        user_id=user_a.id,
        title="t",
        content="body",
        mode=CapsuleMode.free,
        status=CapsuleStatus.locked,
        open_date=datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=1),
        notification_email="dest@example.com",
    )
    db.add(c)
    db.commit()
    db.refresh(c)
    return c


@pytest.fixture()
def scheduler_env(monkeypatch, db):
    monkeypatch.setattr(settings, "brevo_api_key", "test")
    monkeypatch.setattr(settings, "mail_from_email", "noreply@example.com")
    # 讓排程器用測試 DB session；close 改為 no-op，讓測試後續還能斷言
    monkeypatch.setattr(sched, "SessionLocal", lambda: db)
    monkeypatch.setattr(db, "close", lambda: None)


def _http_error(status):
    req = httpx.Request("POST", "https://api.brevo.com/v3/smtp/email")
    resp = httpx.Response(status, request=req, text="brevo says no")
    return httpx.HTTPStatusError("boom", request=req, response=resp)


def test_success_marks_sent(scheduler_env, monkeypatch, db, due_capsule):
    monkeypatch.setattr(sched, "send_capsule_ready_email", lambda **kw: None)
    assert sched.check_due_capsules() == {"sent": 1, "failed": 0}
    db.refresh(due_capsule)
    assert due_capsule.notification_sent_at is not None
    # 第二次不會重寄
    assert sched.check_due_capsules() == {"sent": 0, "failed": 0}


def test_4xx_marks_permanent_failure(scheduler_env, monkeypatch, db, due_capsule):
    def boom(**kw):
        raise _http_error(400)
    monkeypatch.setattr(sched, "send_capsule_ready_email", boom)
    assert sched.check_due_capsules() == {"sent": 0, "failed": 1}
    db.refresh(due_capsule)
    assert due_capsule.notification_error is not None
    assert due_capsule.notification_sent_at is None
    # 不再重試
    assert sched.check_due_capsules() == {"sent": 0, "failed": 0}


def test_5xx_is_retried(scheduler_env, monkeypatch, db, due_capsule):
    def boom(**kw):
        raise _http_error(503)
    monkeypatch.setattr(sched, "send_capsule_ready_email", boom)
    assert sched.check_due_capsules() == {"sent": 0, "failed": 1}
    db.refresh(due_capsule)
    assert due_capsule.notification_error is None  # 保持可重試
    # 下一輪仍會嘗試
    assert sched.check_due_capsules() == {"sent": 0, "failed": 1}
