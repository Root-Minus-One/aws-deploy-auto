"use client";

import React from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Message } from "@/lib/api";
import FilePreview from "./FilePreview";
import { User, Sparkles, Copy, Check } from "lucide-react";

interface MessageBubbleProps {
  message: Message;
}

export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === "user";
  const [copied, setCopied] = React.useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(message.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className={`flex items-start gap-4 py-4 px-4 max-w-4xl mx-auto group ${isUser ? "" : ""}`}>
      {/* Avatar */}
      <div
        className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
          isUser
            ? "bg-gradient-to-br from-emerald-500 to-teal-600"
            : "bg-gradient-to-br from-blue-500 to-purple-500"
        }`}
      >
        {isUser ? (
          <User className="w-4 h-4 text-white" />
        ) : (
          <Sparkles className="w-4 h-4 text-white" />
        )}
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1">
          <span className="text-sm font-semibold text-[#E8EAED]">
            {isUser ? "You" : "Gemini"}
          </span>
          <span className="text-xs text-[#9AA0A6]">
            {new Date(message.timestamp).toLocaleTimeString([], {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </span>
        </div>

        {/* Files */}
        {message.files && message.files.length > 0 && (
          <div className="flex flex-wrap gap-3 mb-3">
            {message.files.map((file) => (
              <FilePreview key={file.file_id} file={file} />
            ))}
          </div>
        )}

        {/* Text content */}
        <div
          className={`prose prose-invert max-w-none text-[#E8EAED] leading-relaxed ${
            isUser ? "text-[15px]" : "text-[15px]"
          }`}
        >
          {isUser ? (
            <p className="whitespace-pre-wrap m-0">{message.content}</p>
          ) : (
            <ReactMarkdown
              remarkPlugins={[remarkGfm]}
              components={{
                code({ className, children, ...props }) {
                  const match = /language-(\w+)/.exec(className || "");
                  const isInline = !match;
                  return isInline ? (
                    <code
                      className="px-1.5 py-0.5 rounded-md bg-[#303134] text-[#F28B82] text-[13px] font-mono"
                      {...props}
                    >
                      {children}
                    </code>
                  ) : (
                    <div className="relative my-3 rounded-xl overflow-hidden bg-[#1E1F20] border border-[#3C4043]">
                      <div className="flex items-center justify-between px-4 py-2 bg-[#282A2C] border-b border-[#3C4043]">
                        <span className="text-xs text-[#9AA0A6] font-mono">{match[1]}</span>
                        <button
                          onClick={handleCopy}
                          className="text-[#9AA0A6] hover:text-[#E8EAED] transition-colors"
                        >
                          {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
                        </button>
                      </div>
                      <pre className="p-4 overflow-x-auto text-[13px] !bg-transparent !m-0">
                        <code className={`${className} !bg-transparent`} {...props}>
                          {children}
                        </code>
                      </pre>
                    </div>
                  );
                },
                table({ children }) {
                  return (
                    <div className="overflow-x-auto my-3 rounded-xl border border-[#3C4043]">
                      <table className="w-full text-sm">{children}</table>
                    </div>
                  );
                },
                th({ children }) {
                  return (
                    <th className="px-4 py-2 bg-[#303134] text-left text-[#E8EAED] font-semibold border-b border-[#3C4043]">
                      {children}
                    </th>
                  );
                },
                td({ children }) {
                  return (
                    <td className="px-4 py-2 border-b border-[#3C4043]/50 text-[#BDC1C6]">
                      {children}
                    </td>
                  );
                },
                a({ href, children }) {
                  return (
                    <a
                      href={href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-[#8AB4F8] hover:underline"
                    >
                      {children}
                    </a>
                  );
                },
                blockquote({ children }) {
                  return (
                    <blockquote className="border-l-4 border-[#8AB4F8]/50 pl-4 my-3 text-[#BDC1C6] italic">
                      {children}
                    </blockquote>
                  );
                },
              }}
            >
              {message.content}
            </ReactMarkdown>
          )}
        </div>

        {/* Copy button for AI responses */}
        {!isUser && (
          <div className="flex items-center gap-2 mt-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 text-xs text-[#9AA0A6] hover:text-[#E8EAED] transition-colors px-2 py-1 rounded-lg hover:bg-[#303134]"
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5" /> Copied
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" /> Copy
                </>
              )}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
