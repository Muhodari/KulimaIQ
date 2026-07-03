"""API integration tests with mocked MongoDB and ML model."""

from io import BytesIO

from PIL import Image


def _tiny_jpeg() -> bytes:
    buf = BytesIO()
    Image.new("RGB", (64, 64), color=(20, 120, 40)).save(buf, format="JPEG")
    return buf.getvalue()


def test_health_ok(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["mongodb_connected"] is True
    assert data["ml_model_ready"] is True
    assert data["num_classes"] >= 1


def test_register_and_login(client):
    register = client.post(
        "/auth/register",
        json={
            "phone": "0781234567",
            "password": "secret12",
            "display_name": "Test Farmer",
        },
    )
    assert register.status_code == 201
    token = register.json()["access_token"]
    assert token

    login = client.post(
        "/auth/login",
        json={"phone": "0781234567", "password": "secret12"},
    )
    assert login.status_code == 200
    assert login.json()["user"]["display_name"] == "Test Farmer"


def test_register_duplicate_phone_conflict(client):
    payload = {
        "phone": "0789999999",
        "password": "secret12",
        "display_name": "Farmer One",
    }
    assert client.post("/auth/register", json=payload).status_code == 201
    duplicate = client.post("/auth/register", json=payload)
    assert duplicate.status_code == 409


def test_analyze_image_requires_auth(client):
    res = client.post(
        "/analyze/image",
        data={"crop": "tomato"},
        files={"image": ("leaf.jpg", _tiny_jpeg(), "image/jpeg")},
    )
    assert res.status_code == 401


def test_analyze_image_returns_disease(client):
    register = client.post(
        "/auth/register",
        json={
            "phone": "0785550000",
            "password": "secret12",
            "display_name": "Scanner",
        },
    )
    token = register.json()["access_token"]

    res = client.post(
        "/analyze/image",
        data={"crop": "tomato"},
        files={"image": ("leaf.jpg", _tiny_jpeg(), "image/jpeg")},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["disease"] == "tomato_late_blight"
    assert body["confidence"] > 0
    assert body["diagnosis_id"]


def test_crops_classes_lists_model(client):
    res = client.get("/crops/classes")
    assert res.status_code == 200
    data = res.json()
    assert data["model_loaded"] is True
    assert "tomato_late_blight" in data["raw_classes"]
    crop_ids = {crop["id"] for crop in data["crops"]}
    assert "tomato" in crop_ids
