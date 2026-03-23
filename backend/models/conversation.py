"""Pydantic models for conversations and messages."""

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class MessageRole(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"


class FileInfo(BaseModel):
    """File metadata attached to a message."""
    file_id: str
    filename: str
    content_type: str
    size: int
    url: str  # Download URL


class Message(BaseModel):
    """A single message in a conversation."""
    role: MessageRole
    content: str
    files: list[FileInfo] = Field(default_factory=list)
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class Conversation(BaseModel):
    """A conversation containing messages."""
    id: Optional[str] = Field(None, alias="_id")
    title: str = "New Chat"
    messages: list[Message] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True


# --- Request/Response schemas ---

class ChatRequest(BaseModel):
    """Request body for sending a chat message."""
    conversation_id: Optional[str] = None
    message: str


class ChatResponse(BaseModel):
    """Response body for a chat message."""
    conversation_id: str
    response: str
    files: list[FileInfo] = Field(default_factory=list)


class ConversationSummary(BaseModel):
    """Summary for conversation list."""
    id: str
    title: str
    message_count: int
    created_at: datetime
    updated_at: datetime


class ConversationDetail(BaseModel):
    """Full conversation with all messages."""
    id: str
    title: str
    messages: list[Message]
    created_at: datetime
    updated_at: datetime
