"""Capsule API 基本行為 + 安全性測試。"""
import datetime

from app.models.capsule import Capsule, CapsuleMode, CapsuleStatus


def _future(days=30):
    return (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=days)).isoformat()


def _create_payload(**overrides):
    payload = {
        "title": "test title",
        "content": "dear future me",
        "mode": "free",
        "open_date": _future(),
        "answers": [],
    }
    payload.update(overrides)
    return payload


def _insert_capsule(db, user, *, open_date=None, status=CapsuleStatus.locked):
    """直接塞 DB，繞過 API 的「不能選過去時間」檢查。"""
    capsule = Capsule(
        user_id=user.id,
        title="t",
        content="secret letter body",
        mode=CapsuleMode.free,
        status=status,
        open_date=open_date or datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=1),
    )
    db.add(capsule)
    db.commit()
    db.refresh(capsule)
    return capsule


def test_create_and_list(client):
    res = client.post("/capsules", json=_create_payload())
    assert res.status_code == 201, res.text
    res = client.get("/capsules")
    assert res.status_code == 200
    items = res.json()
    assert len(items) == 1
    assert "content" not in items[0]  # 列表不能有信件內文


def test_create_past_date_rejected(client):
    past = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=1)).isoformat()
    res = client.post("/capsules", json=_create_payload(open_date=past))
    assert res.status_code == 400


def test_cannot_access_others_capsule(db, make_client, user_a, user_b):
    capsule = _insert_capsule(db, user_a)
    client_b = make_client(user_b)
    assert client_b.get(f"/capsules/{capsule.id}").status_code == 404
    assert client_b.post(f"/capsules/{capsule.id}/open").status_code == 404
    assert client_b.delete(f"/capsules/{capsule.id}").status_code == 404


def test_open_before_date_rejected(db, client, user_a):
    capsule = _insert_capsule(
        db, user_a,
        open_date=datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=3),
    )
    res = client.post(f"/capsules/{capsule.id}/open")
    assert res.status_code == 400


def test_open_after_date_succeeds(db, client, user_a):
    capsule = _insert_capsule(db, user_a)  # open_date 已過
    res = client.post(f"/capsules/{capsule.id}/open")
    assert res.status_code == 200
    assert res.json()["status"] == "opened"
    # 開封後不能再開
    assert client.post(f"/capsules/{capsule.id}/open").status_code == 400


def test_locked_capsule_hides_content_and_answers(db, client, user_a):
    """未開封的信不能從 API 讀到內文（核心產品承諾）。"""
    res = client.post("/capsules", json=_create_payload(
        answers=[{"question_number": 1, "question_text": "q1", "answer_text": "secret answer"}],
    ))
    assert res.status_code == 201
    cid = res.json()["id"]

    detail = client.get(f"/capsules/{cid}").json()
    assert detail["status"] == "locked"
    assert detail["content"] is None
    assert detail["answers"] == []

    # 開封後才看得到全文
    capsule = db.query(Capsule).filter(Capsule.id == cid).first()
    capsule.open_date = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(minutes=1)
    db.commit()
    assert client.post(f"/capsules/{cid}/open").status_code == 200
    detail = client.get(f"/capsules/{cid}").json()
    assert detail["content"] == "dear future me"
    assert detail["answers"][0]["answer_text"] == "secret answer"


def test_title_over_200_chars_rejected(client):
    """DB 欄位 String(200)，缺驗證時會直接 500。"""
    res = client.post("/capsules", json=_create_payload(title="x" * 201))
    assert res.status_code == 422
    res = client.post("/capsules", json=_create_payload(title="x" * 200))
    assert res.status_code == 201
