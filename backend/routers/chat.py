"""Chat router — all conversation and messaging endpoints."""

import logging
from datetime import datetime
from typing import Optional
from bson import ObjectId
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
import io

from db.mongo import get_database
from models.conversation import (
    ChatRequest,
    ChatResponse,
    ConversationDetail,
    ConversationSummary,
    FileInfo,
    Message,
    MessageRole,
)
from services import gemini_service, file_service, cache_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api", tags=["chat"])


# ──────────────────────── Conversations ────────────────────────


@router.get("/conversations", response_model=list[ConversationSummary])
async def list_conversations():
    """List all conversations, newest first."""
    # Check cache
    cached = await cache_service.get_cached("conversations:list")
    if cached:
        return cached

    db = get_database()
    cursor = db.conversations.find(
        {},
        {"title": 1, "messages": {"$slice": -1}, "created_at": 1, "updated_at": 1},
    ).sort("updated_at", -1)

    conversations = []
    async for doc in cursor:
        # Get message count
        full_doc = await db.conversations.find_one(
            {"_id": doc["_id"]}, {"messages": 1}
        )
        msg_count = len(full_doc.get("messages", [])) if full_doc else 0
        conversations.append(
            ConversationSummary(
                id=str(doc["_id"]),
                title=doc.get("title", "New Chat"),
                message_count=msg_count,
                created_at=doc.get("created_at", datetime.utcnow()),
                updated_at=doc.get("updated_at", datetime.utcnow()),
            )
        )

    await cache_service.set_cached("conversations:list", conversations, ttl=60)
    return conversations


@router.post("/conversations", response_model=dict)
async def create_conversation():
    """Create a new conversation."""
    db = get_database()
    now = datetime.utcnow()
    result = await db.conversations.insert_one(
        {
            "title": "New Chat",
            "messages": [],
            "created_at": now,
            "updated_at": now,
        }
    )
    await cache_service.invalidate_pattern("conversations:*")
    logger.info(f"Created conversation: {result.inserted_id}")
    return {"id": str(result.inserted_id)}


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(conversation_id: str):
    """Get a conversation with all messages."""
    cached = await cache_service.get_cached(f"conversation:{conversation_id}")
    if cached:
        return cached

    db = get_database()
    try:
        doc = await db.conversations.find_one({"_id": ObjectId(conversation_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid conversation ID")

    if not doc:
        raise HTTPException(status_code=404, detail="Conversation not found")

    result = ConversationDetail(
        id=str(doc["_id"]),
        title=doc.get("title", "New Chat"),
        messages=doc.get("messages", []),
        created_at=doc.get("created_at", datetime.utcnow()),
        updated_at=doc.get("updated_at", datetime.utcnow()),
    )
    await cache_service.set_cached(f"conversation:{conversation_id}", result, ttl=300)
    return result


@router.delete("/conversations/{conversation_id}")
async def delete_conversation(conversation_id: str):
    """Delete a conversation."""
    db = get_database()
    try:
        result = await db.conversations.delete_one({"_id": ObjectId(conversation_id)})
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid conversation ID")

    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Conversation not found")

    # Delete associated files
    await db.files.delete_many({"conversation_id": conversation_id})

    # Invalidate caches
    await cache_service.delete_cached(f"conversation:{conversation_id}")
    await cache_service.invalidate_pattern("conversations:*")

    logger.info(f"Deleted conversation: {conversation_id}")
    return {"status": "deleted"}


# ──────────────────────── Chat ────────────────────────


@router.post("/chat", response_model=ChatResponse)
async def send_message(
    message: str = Form(""),
    conversation_id: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
):
    """Send a message (with optional file) and get a Gemini response."""
    db = get_database()

    # Create or fetch conversation
    if conversation_id:
        try:
            conv = await db.conversations.find_one({"_id": ObjectId(conversation_id)})
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid conversation ID")
        if not conv:
            raise HTTPException(status_code=404, detail="Conversation not found")
    else:
        now = datetime.utcnow()
        result = await db.conversations.insert_one(
            {"title": "New Chat", "messages": [], "created_at": now, "updated_at": now}
        )
        conversation_id = str(result.inserted_id)
        conv = await db.conversations.find_one({"_id": result.inserted_id})

    # Process file if attached
    file_info_list = []
    file_bytes = None
    file_mime = None

    if file:
        file_bytes = await file.read()
        file_mime = file.content_type or "application/octet-stream"

        # Validate
        try:
            file_service.validate_file(file.filename, file_mime, len(file_bytes))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

        # Save file
        file_meta = await file_service.save_file(file_bytes, file.filename, file_mime)

        # Store file metadata in DB
        file_meta["conversation_id"] = conversation_id
        await db.files.insert_one(file_meta)

        file_info = FileInfo(
            file_id=file_meta["file_id"],
            filename=file_meta["filename"],
            content_type=file_meta["content_type"],
            size=file_meta["size"],
            url=f"/api/files/{file_meta['file_id']}",
        )
        file_info_list.append(file_info)

    # Build message content (include file text extraction if applicable)
    full_message = message
    if file_bytes and file_mime:
        if file_mime.startswith("image/"):
            # For images, we'll use multimodal
            pass
        else:
            # Extract text from document for context
            extracted_text = file_service.extract_text_from_file(file_bytes, file_mime)
            if extracted_text:
                full_message = (
                    f"{message}\n\n---\n"
                    f"[Attached file: {file.filename}]\n"
                    f"File content:\n{extracted_text[:10000]}"
                )

    # Prepare conversation history (last 20 messages for context window)
    history = []
    existing_messages = conv.get("messages", [])
    for msg in existing_messages[-20:]:
        history.append({"role": msg["role"], "content": msg["content"]})

    # Generate response from Gemini
    try:
        if file_bytes and file_mime and file_mime.startswith("image/"):
            ai_response = await gemini_service.generate_multimodal_response(
                message=message or "What is in this image?",
                file_bytes=file_bytes,
                mime_type=file_mime,
                history=history,
            )
        elif file_bytes and file_mime and file_mime == "application/pdf":
            ai_response = await gemini_service.generate_multimodal_response(
                message=full_message or "Summarize this document.",
                file_bytes=file_bytes,
                mime_type=file_mime,
                history=history,
            )
        else:
            ai_response = await gemini_service.generate_text_response(
                message=full_message,
                history=history,
            )
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        raise HTTPException(status_code=500, detail=f"AI generation failed: {str(e)}")

    # Auto-generate title from first message
    update_title = {}
    if len(existing_messages) == 0 and message:
        title = message[:50] + ("..." if len(message) > 50 else "")
        update_title = {"title": title}

    # Save user message and AI response to conversation
    user_msg = {
        "role": "user",
        "content": message,
        "files": [fi.model_dump() for fi in file_info_list],
        "timestamp": datetime.utcnow(),
    }
    ai_msg = {
        "role": "assistant",
        "content": ai_response,
        "files": [],
        "timestamp": datetime.utcnow(),
    }

    await db.conversations.update_one(
        {"_id": ObjectId(conversation_id)},
        {
            "$push": {"messages": {"$each": [user_msg, ai_msg]}},
            "$set": {"updated_at": datetime.utcnow(), **update_title},
        },
    )

    # Invalidate caches
    await cache_service.delete_cached(f"conversation:{conversation_id}")
    await cache_service.invalidate_pattern("conversations:*")

    logger.info(
        f"Chat in {conversation_id}: user={len(message)} chars, "
        f"ai={len(ai_response)} chars, files={len(file_info_list)}"
    )

    return ChatResponse(
        conversation_id=conversation_id,
        response=ai_response,
        files=file_info_list,
    )


# ──────────────────────── Files ────────────────────────


@router.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    """Upload a file without sending a chat message."""
    file_bytes = await file.read()
    file_mime = file.content_type or "application/octet-stream"

    try:
        file_service.validate_file(file.filename, file_mime, len(file_bytes))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    file_meta = await file_service.save_file(file_bytes, file.filename, file_mime)

    db = get_database()
    await db.files.insert_one(file_meta)

    return {
        "file_id": file_meta["file_id"],
        "filename": file_meta["filename"],
        "content_type": file_meta["content_type"],
        "size": file_meta["size"],
        "url": f"/api/files/{file_meta['file_id']}",
    }


@router.get("/files/{file_id}")
async def download_file(file_id: str):
    """Download a file by its ID."""
    db = get_database()
    file_doc = await db.files.find_one({"file_id": file_id})
    if not file_doc:
        raise HTTPException(status_code=404, detail="File not found")

    file_bytes = await file_service.get_file_bytes(file_doc["stored_name"])
    if file_bytes is None:
        raise HTTPException(status_code=404, detail="File data not found on disk")

    return StreamingResponse(
        io.BytesIO(file_bytes),
        media_type=file_doc["content_type"],
        headers={
            "Content-Disposition": f'inline; filename="{file_doc["filename"]}"',
            "Content-Length": str(len(file_bytes)),
        },
    )
