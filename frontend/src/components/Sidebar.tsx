"use client";

import React from "react";
import { ConversationSummary } from "@/lib/api";
import {
  MessageSquare,
  Plus,
  Trash2,
  X,
  Sparkles,
} from "lucide-react";

interface SidebarProps {
  conversations: ConversationSummary[];
  activeId: string | null;
  isOpen: boolean;
  onSelect: (id: string) => void;
  onNew: () => void;
  onDelete: (id: string) => void;
  onClose: () => void;
}

export default function Sidebar({
  conversations,
  activeId,
  isOpen,
  onSelect,
  onNew,
  onDelete,
  onClose,
}: SidebarProps) {
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return "Just now";
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 md:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed md:relative top-0 left-0 z-50 h-full w-72 bg-[#1E1F20] border-r border-[#3C4043] flex flex-col transition-transform duration-300 ease-in-out ${
          isOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0 md:w-0 md:border-0 md:overflow-hidden"
        }`}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-[#3C4043]">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-white" />
            </div>
            <span className="font-semibold text-[#E8EAED] text-lg">Gemini</span>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-[#9AA0A6] hover:text-[#E8EAED] hover:bg-[#303134] transition-colors md:hidden"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* New Chat button */}
        <div className="p-3">
          <button
            onClick={onNew}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-xl bg-[#303134] hover:bg-[#3C4043] border border-[#3C4043] hover:border-[#8AB4F8]/30 text-[#E8EAED] transition-all duration-200 group"
          >
            <Plus className="w-5 h-5 text-[#8AB4F8] group-hover:rotate-90 transition-transform duration-200" />
            <span className="text-sm font-medium">New Chat</span>
          </button>
        </div>

        {/* Conversation list */}
        <div className="flex-1 overflow-y-auto px-3 pb-3 space-y-1 scrollbar-thin scrollbar-thumb-[#5F6368] scrollbar-track-transparent">
          {conversations.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <MessageSquare className="w-10 h-10 text-[#5F6368] mb-3" />
              <p className="text-sm text-[#9AA0A6]">No conversations yet</p>
              <p className="text-xs text-[#5F6368] mt-1">Start a new chat!</p>
            </div>
          ) : (
            conversations.map((conv) => (
              <div
                key={conv.id}
                onClick={() => onSelect(conv.id)}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl cursor-pointer transition-all duration-200 group ${
                  activeId === conv.id
                    ? "bg-[#303134] border border-[#8AB4F8]/30"
                    : "hover:bg-[#303134] border border-transparent"
                }`}
              >
                <MessageSquare
                  className={`w-4 h-4 flex-shrink-0 ${
                    activeId === conv.id ? "text-[#8AB4F8]" : "text-[#9AA0A6]"
                  }`}
                />
                <div className="flex-1 min-w-0">
                  <p
                    className={`text-sm truncate ${
                      activeId === conv.id
                        ? "text-[#E8EAED] font-medium"
                        : "text-[#BDC1C6]"
                    }`}
                  >
                    {conv.title}
                  </p>
                  <p className="text-xs text-[#9AA0A6] mt-0.5">
                    {formatDate(conv.updated_at)}
                  </p>
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onDelete(conv.id);
                  }}
                  className="p-1 rounded-lg text-[#9AA0A6] hover:text-[#EA4335] hover:bg-[#EA4335]/10 transition-colors opacity-0 group-hover:opacity-100"
                  title="Delete"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            ))
          )}
        </div>
      </aside>
    </>
  );
}
