"""
NexusAuth Backend - Automated Test Suite
Run with:
    python test_api.py
"""

from fastapi.testclient import TestClient
from main import app, create_jwt_token

client = TestClient(app)


def test_login_success():
    response = client.post(
        "/api/login",
        json={"username": "admin", "password": "123456"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_invalid():
    response = client.post(
        "/api/login",
        json={"username": "admin", "password": "wrong_password"}
    )
    assert response.status_code == 401


def test_protected_data_unauthorized():
    response = client.get("/api/protected-data")
    assert response.status_code in (401, 403)


def test_protected_data_with_token():
    login_resp = client.post(
        "/api/login",
        json={"username": "admin", "password": "123456"}
    )
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/api/protected-data", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "admin" in data["message"]


if __name__ == "__main__":
    print("Testing NexusAuth Backend...")
    test_login_success()
    print("[PASS] test_login_success")
    test_login_invalid()
    print("[PASS] test_login_invalid")
    test_protected_data_unauthorized()
    print("[PASS] test_protected_data_unauthorized")
    test_protected_data_with_token()
    print("[PASS] test_protected_data_with_token")
    print("All backend tests passed successfully!")
