"use client";

import React, { useState, useEffect, useCallback } from "react";
import Sidebar from "@/components/Sidebar";
import ChatWindow from "@/components/ChatWindow";
import InputBar from "@/components/InputBar";
import { DragOverlay } from "@/components/FileUpload";
import {
  ConversationSummary,
  Message,
  listConversations,
  createConversation,
  getConversation,
  deleteConversation,
  sendMessage,
} from "@/lib/api";
import { Menu, PanelLeftClose } from "lucide-react";
import { useDropzone } from "react-dropzone";

export default function Home() {
  const [conversations, setConversations] = useState<ConversationSummary[]>([]);
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [dragFile, setDragFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Global drag & drop
  const { isDragActive } = useDropzone({
    noClick: true,
    noKeyboard: true,
    onDrop: (files) => {
      if (files.length > 0) {
        setDragFile(files[0]);
        // Auto-send with file
        handleSend("", files[0]);
      }
    },
  });

  // Load conversations on mount
  useEffect(() => {
    loadConversations();
  }, []);

  const loadConversations = async () => {
    try {
      const convos = await listConversations();
      setConversations(convos);
    } catch {
      console.error("Failed to load conversations");
    }
  };

  const handleSelectConversation = useCallback(async (id: string) => {
    setActiveConversationId(id);
    setError(null);
    try {
      const conv = await getConversation(id);
      setMessages(conv.messages);
    } catch {
      setError("Failed to load conversation");
      setMessages([]);
    }
  }, []);

  const handleNewChat = useCallback(() => {
    setActiveConversationId(null);
    setMessages([]);
    setError(null);
  }, []);

  const handleDeleteConversation = useCallback(
    async (id: string) => {
      try {
        await deleteConversation(id);
        if (activeConversationId === id) {
          setActiveConversationId(null);
          setMessages([]);
        }
        await loadConversations();
      } catch {
        setError("Failed to delete conversation");
      }
    },
    [activeConversationId]
  );

  const handleSend = useCallback(
    async (message: string, file?: File) => {
      if (!message.trim() && !file) return;

      setIsLoading(true);
      setError(null);

      // Optimistically add user message
      const userMsg: Message = {
        role: "user",
        content: message,
        files: file
          ? [
              {
                file_id: "pending",
                filename: file.name,
                content_type: file.type,
                size: file.size,
                url: "",
              },
            ]
          : [],
        timestamp: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, userMsg]);

      try {
        const response = await sendMessage(
          message,
          activeConversationId || undefined,
          file
        );

        // Update conversation ID if new
        if (!activeConversationId) {
          setActiveConversationId(response.conversation_id);
        }

        // Add AI response
        const aiMsg: Message = {
          role: "assistant",
          content: response.response,
          files: response.files,
          timestamp: new Date().toISOString(),
        };
        setMessages((prev) => {
          // Replace the optimistic user message files with real ones
          const updated = [...prev];
          if (response.files.length > 0) {
            const lastUserIdx = updated.length - 1;
            if (updated[lastUserIdx]?.role === "user") {
              updated[lastUserIdx] = {
                ...updated[lastUserIdx],
                files: response.files,
              };
            }
          }
          return [...updated, aiMsg];
        });

        // Reload conversations list
        await loadConversations();
      } catch (err) {
        setError(err instanceof Error ? err.message : "Something went wrong");
        // Remove the optimistic message on error
        setMessages((prev) => prev.slice(0, -1));
      } finally {
        setIsLoading(false);
        setDragFile(null);
      }
    },
    [activeConversationId]
  );

  return (
    <div className="flex h-screen bg-[#131314] text-[#E8EAED] overflow-hidden">
      {/* Sidebar */}
      <Sidebar
        conversations={conversations}
        activeId={activeConversationId}
        isOpen={sidebarOpen}
        onSelect={handleSelectConversation}
        onNew={handleNewChat}
        onDelete={handleDeleteConversation}
        onClose={() => setSidebarOpen(false)}
      />

      {/* Main content */}
      <main className="flex-1 flex flex-col min-w-0">
        {/* Top bar */}
        <header className="flex items-center gap-3 px-4 py-3 border-b border-[#3C4043]/50">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-2 rounded-xl text-[#9AA0A6] hover:text-[#E8EAED] hover:bg-[#303134] transition-colors"
          >
            {sidebarOpen ? (
              <PanelLeftClose className="w-5 h-5" />
            ) : (
              <Menu className="w-5 h-5" />
            )}
          </button>
          <h1 className="text-lg font-semibold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
            Gemini Chat
          </h1>
          {activeConversationId && (
            <span className="text-xs text-[#5F6368] font-mono ml-auto hidden sm:block">
              {activeConversationId.slice(0, 8)}...
            </span>
          )}
        </header>

        {/* Error banner */}
        {error && (
          <div className="mx-4 mt-2 px-4 py-2 rounded-xl bg-[#EA4335]/10 border border-[#EA4335]/30 text-[#F28B82] text-sm flex items-center justify-between">
            <span>{error}</span>
            <button
              onClick={() => setError(null)}
              className="text-[#F28B82] hover:text-white transition-colors ml-4"
            >
              ✕
            </button>
          </div>
        )}

        {/* Chat window */}
        <ChatWindow messages={messages} isLoading={isLoading} />

        {/* Input bar */}
        <InputBar onSend={handleSend} isLoading={isLoading} />
      </main>

      {/* Drag overlay */}
      <DragOverlay isDragActive={isDragActive} />
    </div>
  );
}
