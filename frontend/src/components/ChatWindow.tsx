"use client";

import React, { useEffect, useRef } from "react";
import { Message } from "@/lib/api";
import MessageBubble from "./MessageBubble";
import { Sparkles } from "lucide-react";

interface ChatWindowProps {
  messages: Message[];
  isLoading: boolean;
}

export default function ChatWindow({ messages, isLoading }: ChatWindowProps) {
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isLoading]);

  if (messages.length === 0 && !isLoading) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center px-6">
        <div className="relative mb-8">
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500 flex items-center justify-center shadow-2xl shadow-purple-500/30 animate-pulse">
            <Sparkles className="w-10 h-10 text-white" />
          </div>
          <div className="absolute -inset-2 rounded-full bg-gradient-to-br from-blue-500/20 via-purple-500/20 to-pink-500/20 blur-xl -z-10" />
        </div>
        <h2 className="text-3xl font-bold bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent mb-3">
          Hello! How can I help you?
        </h2>
        <p className="text-[#9AA0A6] text-center max-w-md text-base leading-relaxed">
          Ask me anything — I can analyze images, PDFs, Word documents, Excel sheets, and more.
          Attach a file to get started!
        </p>
        <div className="grid grid-cols-2 gap-3 mt-8 max-w-lg w-full">
          {[
            { icon: "📄", text: "Summarize a PDF document" },
            { icon: "🖼️", text: "Describe what's in an image" },
            { icon: "📊", text: "Analyze an Excel spreadsheet" },
            { icon: "✍️", text: "Help me write content" },
          ].map((suggestion, i) => (
            <div
              key={i}
              className="flex items-center gap-3 px-4 py-3 rounded-xl bg-[#303134] hover:bg-[#3C4043] border border-[#5F6368]/30 cursor-pointer transition-all duration-200 hover:border-[#8AB4F8]/30 group"
            >
              <span className="text-xl">{suggestion.icon}</span>
              <span className="text-sm text-[#BDC1C6] group-hover:text-[#E8EAED] transition-colors">
                {suggestion.text}
              </span>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto px-4 py-6 space-y-1 scrollbar-thin scrollbar-thumb-[#5F6368] scrollbar-track-transparent">
      {messages.map((msg, index) => (
        <MessageBubble key={index} message={msg} />
      ))}

      {isLoading && (
        <div className="flex items-start gap-4 py-4 px-4 max-w-4xl mx-auto">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center flex-shrink-0">
            <Sparkles className="w-4 h-4 text-white" />
          </div>
          <div className="flex items-center gap-1.5 pt-2">
            <div className="w-2 h-2 rounded-full bg-blue-400 animate-bounce [animation-delay:0ms]" />
            <div className="w-2 h-2 rounded-full bg-purple-400 animate-bounce [animation-delay:150ms]" />
            <div className="w-2 h-2 rounded-full bg-pink-400 animate-bounce [animation-delay:300ms]" />
          </div>
        </div>
      )}

      <div ref={bottomRef} />
    </div>
  );
}
