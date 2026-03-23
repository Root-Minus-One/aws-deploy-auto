"use client";

import React from "react";
import { FileInfo, getFileUrl } from "@/lib/api";
import {
  FileText,
  FileSpreadsheet,
  Image as ImageIcon,
  File as FileIcon,
  Download,
  ExternalLink,
} from "lucide-react";

interface FilePreviewProps {
  file: FileInfo;
}

function getFileIcon(contentType: string) {
  if (contentType.startsWith("image/")) return <ImageIcon className="w-5 h-5" />;
  if (contentType === "application/pdf") return <FileText className="w-5 h-5 text-red-400" />;
  if (
    contentType.includes("wordprocessingml") ||
    contentType === "application/msword"
  )
    return <FileText className="w-5 h-5 text-blue-400" />;
  if (
    contentType.includes("spreadsheetml") ||
    contentType === "application/vnd.ms-excel"
  )
    return <FileSpreadsheet className="w-5 h-5 text-green-400" />;
  return <FileIcon className="w-5 h-5 text-[#9AA0A6]" />;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function FilePreview({ file }: FilePreviewProps) {
  const isImage = file.content_type.startsWith("image/");
  const fileUrl = getFileUrl(file.file_id);

  if (isImage) {
    return (
      <div className="relative group/file inline-block rounded-xl overflow-hidden border border-[#3C4043] max-w-xs">
        <img
          src={fileUrl}
          alt={file.filename}
          className="max-w-full max-h-64 object-contain bg-[#1E1F20]"
          loading="lazy"
        />
        <div className="absolute inset-0 bg-black/50 opacity-0 group-hover/file:opacity-100 transition-opacity flex items-center justify-center gap-2">
          <a
            href={fileUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="p-2 bg-white/10 backdrop-blur-sm rounded-lg hover:bg-white/20 transition-colors"
            title="Open in new tab"
          >
            <ExternalLink className="w-5 h-5 text-white" />
          </a>
          <a
            href={fileUrl}
            download={file.filename}
            className="p-2 bg-white/10 backdrop-blur-sm rounded-lg hover:bg-white/20 transition-colors"
            title="Download"
          >
            <Download className="w-5 h-5 text-white" />
          </a>
        </div>
        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent px-3 py-2">
          <p className="text-xs text-white/80 truncate">{file.filename}</p>
        </div>
      </div>
    );
  }

  // Non-image files (PDF, Word, Excel, etc.)
  return (
    <div className="flex items-center gap-3 px-4 py-3 rounded-xl bg-[#303134] border border-[#3C4043] hover:bg-[#3C4043] transition-colors max-w-xs group/file">
      <div className="w-10 h-10 rounded-lg bg-[#1E1F20] flex items-center justify-center flex-shrink-0">
        {getFileIcon(file.content_type)}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm text-[#E8EAED] truncate font-medium">{file.filename}</p>
        <p className="text-xs text-[#9AA0A6]">{formatFileSize(file.size)}</p>
      </div>
      <a
        href={fileUrl}
        download={file.filename}
        className="p-1.5 rounded-lg text-[#9AA0A6] hover:text-[#E8EAED] hover:bg-[#1E1F20] transition-colors opacity-0 group-hover/file:opacity-100"
        title="Download"
      >
        <Download className="w-4 h-4" />
      </a>
    </div>
  );
}
