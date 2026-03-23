"""Tests for chat endpoints."""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi.testclient import TestClient


# We'll test the routes with mocked services
class TestHealthEndpoint:
    """Tests for health check endpoint."""

    def test_health_check(self):
        """Health endpoint should return healthy status."""
        from main import app
        with patch("main.connect_to_mongo", new_callable=AsyncMock):
            with patch("main.connect_to_redis", new_callable=AsyncMock):
                with patch("main.close_mongo_connection", new_callable=AsyncMock):
                    with patch("main.close_redis_connection", new_callable=AsyncMock):
                        client = TestClient(app)
                        response = client.get("/api/health")
                        assert response.status_code == 200
                        data = response.json()
                        assert data["status"] == "healthy"
                        assert "version" in data
                        assert "timestamp" in data


class TestConversationModels:
    """Tests for Pydantic models."""

    def test_chat_request_model(self):
        from models.conversation import ChatRequest
        req = ChatRequest(message="Hello, Gemini!")
        assert req.message == "Hello, Gemini!"
        assert req.conversation_id is None

    def test_chat_request_with_conversation(self):
        from models.conversation import ChatRequest
        req = ChatRequest(message="Follow-up", conversation_id="abc123")
        assert req.conversation_id == "abc123"

    def test_file_info_model(self):
        from models.conversation import FileInfo
        fi = FileInfo(
            file_id="uuid",
            filename="test.pdf",
            content_type="application/pdf",
            size=1024,
            url="/api/files/uuid",
        )
        assert fi.filename == "test.pdf"
        assert fi.size == 1024

    def test_message_model(self):
        from models.conversation import Message, MessageRole
        msg = Message(role=MessageRole.USER, content="Hello!")
        assert msg.role == "user"
        assert len(msg.files) == 0


class TestFileService:
    """Tests for file service."""

    def test_validate_supported_type(self):
        from services.file_service import validate_file
        # Should not raise
        validate_file("test.pdf", "application/pdf", 1024)

    def test_validate_unsupported_type(self):
        from services.file_service import validate_file
        with pytest.raises(ValueError, match="Unsupported file type"):
            validate_file("test.exe", "application/x-executable", 1024)

    def test_validate_file_too_large(self):
        from services.file_service import validate_file
        with pytest.raises(ValueError, match="File too large"):
            validate_file("test.pdf", "application/pdf", 100 * 1024 * 1024)

    def test_extract_text_plain(self):
        from services.file_service import extract_text_from_file
        text = extract_text_from_file(b"Hello, world!", "text/plain")
        assert text == "Hello, world!"
