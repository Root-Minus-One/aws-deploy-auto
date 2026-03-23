/**
 * API client for communicating with the FastAPI backend.
 */

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

// ── Types ──

export interface FileInfo {
  file_id: string;
  filename: string;
  content_type: string;
  size: number;
  url: string;
}

export interface Message {
  role: "user" | "assistant";
  content: string;
  files: FileInfo[];
  timestamp: string;
}

export interface ConversationSummary {
  id: string;
  title: string;
  message_count: number;
  created_at: string;
  updated_at: string;
}

export interface ConversationDetail {
  id: string;
  title: string;
  messages: Message[];
  created_at: string;
  updated_at: string;
}

export interface ChatResponse {
  conversation_id: string;
  response: string;
  files: FileInfo[];
}

// ── API Functions ──

export async function listConversations(): Promise<ConversationSummary[]> {
  const res = await fetch(`${API_BASE}/api/conversations`);
  if (!res.ok) throw new Error("Failed to fetch conversations");
  return res.json();
}

export async function createConversation(): Promise<{ id: string }> {
  const res = await fetch(`${API_BASE}/api/conversations`, { method: "POST" });
  if (!res.ok) throw new Error("Failed to create conversation");
  return res.json();
}

export async function getConversation(id: string): Promise<ConversationDetail> {
  const res = await fetch(`${API_BASE}/api/conversations/${id}`);
  if (!res.ok) throw new Error("Failed to fetch conversation");
  return res.json();
}

export async function deleteConversation(id: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/conversations/${id}`, {
    method: "DELETE",
  });
  if (!res.ok) throw new Error("Failed to delete conversation");
}

export async function sendMessage(
  message: string,
  conversationId?: string,
  file?: File
): Promise<ChatResponse> {
  const formData = new FormData();
  formData.append("message", message);
  if (conversationId) formData.append("conversation_id", conversationId);
  if (file) formData.append("file", file);

  const res = await fetch(`${API_BASE}/api/chat`, {
    method: "POST",
    body: formData,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: "Chat request failed" }));
    throw new Error(err.detail || "Chat request failed");
  }
  return res.json();
}

export function getFileUrl(fileId: string): string {
  return `${API_BASE}/api/files/${fileId}`;
}

export function getFileDownloadUrl(fileId: string): string {
  return `${API_BASE}/api/files/${fileId}`;
}
