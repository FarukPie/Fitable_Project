from fastapi.testclient import TestClient
from main import app
import pytest

client = TestClient(app)

def test_read_root():
    # As the root "/" is not defined in main.py, it should return 404
    response = client.get("/")
    assert response.status_code == 404

def test_analyze_endpoint_validation():
    # Sending empty body
    response = client.post("/analyze", json={})
    assert response.status_code == 422 # Struct validation error

def test_analyze_endpoint_mock():
    # We will mock the analyzer to avoid real scraping
    pass
