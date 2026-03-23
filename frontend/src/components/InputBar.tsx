"use client";

import React, { useState, useRef, useCallback } from "react";
import { Send, Paperclip, Square } from "lucide-react";
import FileUpload from "./FileUpload";

interface InputBarProps {
  onSend: (message: string, file?: File) => void;
  isLoading: boolean;
  onStop?: () => void;
}

export default function InputBar({ onSend, isLoading, onStop }: InputBarProps) {
  const [input, setInput] = useState("");
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = useCallback(() => {
    if ((!input.trim() && !selectedFile) || isLoading) return;
    onSend(input.trim(), selectedFile || undefined);
    setInput("");
    setSelectedFile(null);
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }
  }, [input, selectedFile, isLoading, onSend]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const handleTextareaChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value);
    // Auto-resize
    const textarea = e.target;
    textarea.style.height = "auto";
    textarea.style.height = `${Math.min(textarea.scrollHeight, 200)}px`;
  };

  const handleFileClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
    }
    // Reset input value so the same file can be selected again
    e.target.value = "";
  };

  return (
    <div className="w-full max-w-4xl mx-auto px-4 pb-4 pt-2">
      <div className="relative bg-[#303134] rounded-2xl border border-[#3C4043] focus-within:border-[#8AB4F8]/50 transition-all duration-200 shadow-lg shadow-black/20">
        {/* Selected file preview */}
        {selectedFile && (
          <div className="px-3 pt-3">
            <FileUpload selectedFile={selectedFile} onFileSelect={setSelectedFile} />
          </div>
        )}

        {/* Input area */}
        <div className="flex items-end gap-2 px-4 py-3">
          {/* Attach button */}
          <button
            onClick={handleFileClick}
            className="p-2 rounded-xl text-[#9AA0A6] hover:text-[#E8EAED] hover:bg-[#3C4043] transition-all duration-200 flex-shrink-0 mb-0.5"
            title="Attach file"
          >
            <Paperclip className="w-5 h-5" />
          </button>

          <input
            ref={fileInputRef}
            type="file"
            className="hidden"
            accept="image/*,.pdf,.docx,.doc,.xlsx,.xls,.txt,.csv"
            onChange={handleFileInputChange}
          />

          {/* Text input */}
          <textarea
            ref={textareaRef}
            value={input}
            onChange={handleTextareaChange}
            onKeyDown={handleKeyDown}
            placeholder="Ask me anything..."
            rows={1}
            className="flex-1 bg-transparent text-[#E8EAED] placeholder-[#9AA0A6] resize-none outline-none text-[15px] leading-relaxed py-1.5 max-h-[200px] scrollbar-thin scrollbar-thumb-[#5F6368] scrollbar-track-transparent"
          />

          {/* Send / Stop button */}
          {isLoading ? (
            <button
              onClick={onStop}
              className="p-2 rounded-xl bg-[#EA4335] text-white hover:bg-[#D93025] transition-all duration-200 flex-shrink-0 mb-0.5"
              title="Stop generating"
            >
              <Square className="w-5 h-5 fill-current" />
            </button>
          ) : (
            <button
              onClick={handleSubmit}
              disabled={!input.trim() && !selectedFile}
              className={`p-2 rounded-xl transition-all duration-200 flex-shrink-0 mb-0.5 ${
                input.trim() || selectedFile
                  ? "bg-gradient-to-r from-blue-500 to-purple-500 text-white hover:from-blue-600 hover:to-purple-600 shadow-md shadow-blue-500/20"
                  : "bg-[#3C4043] text-[#5F6368] cursor-not-allowed"
              }`}
              title="Send message"
            >
              <Send className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>

      <p className="text-center text-xs text-[#9AA0A6] mt-2">
        Gemini can make mistakes. Check important info.
      </p>
    </div>
  );
}
