"""Google Gemini API service for text and multimodal conversations."""

import base64
import logging
from google import genai
from google.genai import types
from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Initialize Gemini client
client = genai.Client(api_key=settings.GEMINI_API_KEY)


async def generate_text_response(
    message: str,
    history: list[dict] | None = None,
) -> str:
    """Generate a text response from Gemini given a message and optional history."""
    try:
        contents = []

        # Build conversation history
        if history:
            for msg in history:
                role = msg["role"]
                # Gemini uses "user" and "model" roles
                gemini_role = "user" if role == "user" else "model"
                contents.append(
                    types.Content(
                        role=gemini_role,
                        parts=[types.Part.from_text(text=msg["content"])],
                    )
                )

        # Add current user message
        contents.append(
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=message)],
            )
        )

        response = client.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                temperature=0.7,
                max_output_tokens=8192,
            ),
        )

        return response.text or "I couldn't generate a response. Please try again."

    except Exception as e:
        logger.error(f"Gemini text generation error: {e}")
        raise


async def generate_multimodal_response(
    message: str,
    file_bytes: bytes,
    mime_type: str,
    history: list[dict] | None = None,
) -> str:
    """Generate a response from Gemini using text + file (image, PDF, etc.)."""
    try:
        contents = []

        # Build conversation history (text only for history)
        if history:
            for msg in history:
                role = msg["role"]
                gemini_role = "user" if role == "user" else "model"
                contents.append(
                    types.Content(
                        role=gemini_role,
                        parts=[types.Part.from_text(text=msg["content"])],
                    )
                )

        # Add current user message with file
        parts = []
        if message:
            parts.append(types.Part.from_text(text=message))

        # Add file as inline data
        encoded = base64.standard_b64encode(file_bytes).decode("utf-8")
        parts.append(
            types.Part.from_bytes(
                data=base64.standard_b64decode(encoded),
                mime_type=mime_type,
            )
        )

        contents.append(types.Content(role="user", parts=parts))

        response = client.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                temperature=0.7,
                max_output_tokens=8192,
            ),
        )

        return response.text or "I couldn't generate a response. Please try again."

    except Exception as e:
        logger.error(f"Gemini multimodal generation error: {e}")
        raise
