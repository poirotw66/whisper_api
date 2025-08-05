import pytest
import asyncio
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data


def test_health_check():
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


def test_list_models():
    """Test the models listing endpoint."""
    response = client.get("/models")
    assert response.status_code == 200
    data = response.json()
    assert "available_models" in data
    assert "default_model" in data
    assert "recommended" in data
    assert len(data["available_models"]) > 0


def test_transcribe_no_file():
    """Test transcription endpoint without file."""
    response = client.post("/transcribe")
    assert response.status_code == 422  # Validation error


def test_detect_language_no_file():
    """Test language detection endpoint without file."""
    response = client.post("/detect-language")
    assert response.status_code == 422  # Validation error


def test_get_nonexistent_task():
    """Test getting a task that doesn't exist."""
    response = client.get("/tasks/nonexistent-task-id")
    assert response.status_code == 404
