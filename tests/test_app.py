import os
import sys

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "app"))
from app import app  # noqa: E402


@pytest.fixture
def client(tmp_path):
    app.config["TESTING"] = True
    app.config["DB_PATH"] = str(tmp_path / "test.db")
    with app.test_client() as c:
        yield c


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_home_page_loads(client):
    r = client.get("/")
    assert r.status_code == 200
    assert b"Employee" in r.data


def test_add_and_list_employee(client):
    client.post("/add", data={"name": "Asha Patil", "department": "HR", "email": "asha@example.com"})
    data = client.get("/api/employees").get_json()
    assert len(data) == 1
    assert data[0]["name"] == "Asha Patil"


def test_search_employee(client):
    client.post("/add", data={"name": "Ravi", "department": "IT", "email": "ravi@example.com"})
    client.post("/add", data={"name": "Meera", "department": "Sales", "email": "meera@example.com"})
    r = client.get("/?q=Sales")
    assert b"Meera" in r.data
    assert b"Ravi" not in r.data


def test_delete_employee(client):
    client.post("/add", data={"name": "Temp", "department": "X", "email": "t@example.com"})
    emp_id = client.get("/api/employees").get_json()[0]["id"]
    client.post(f"/delete/{emp_id}")
    assert client.get("/api/employees").get_json() == []
