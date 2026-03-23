"use client";

import React, { useCallback } from "react";
import { useDropzone } from "react-dropzone";
import { Upload, X, FileText, Image as ImageIcon, FileSpreadsheet, File as FileIcon } from "lucide-react";

interface FileUploadProps {
  selectedFile: File | null;
  onFileSelect: (file: File | null) => void;
}

function getFileIconForType(type: string) {
  if (type.startsWith("image/")) return <ImageIcon className="w-6 h-6 text-purple-400" />;
  if (type === "application/pdf") return <FileText className="w-6 h-6 text-red-400" />;
  if (type.includes("word")) return <FileText className="w-6 h-6 text-blue-400" />;
  if (type.includes("sheet") || type.includes("excel")) return <FileSpreadsheet className="w-6 h-6 text-green-400" />;
  return <FileIcon className="w-6 h-6 text-[#9AA0A6]" />;
}

export default function FileUpload({ selectedFile, onFileSelect }: FileUploadProps) {
  const onDrop = useCallback(
    (acceptedFiles: File[]) => {
      if (acceptedFiles.length > 0) {
        onFileSelect(acceptedFiles[0]);
      }
    },
    [onFileSelect]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    maxFiles: 1,
    maxSize: 20 * 1024 * 1024, // 20MB
    accept: {
      "image/*": [".jpeg", ".jpg", ".png", ".gif", ".webp"],
      "application/pdf": [".pdf"],
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document": [".docx"],
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": [".xlsx"],
      "application/msword": [".doc"],
      "application/vnd.ms-excel": [".xls"],
      "text/plain": [".txt"],
      "text/csv": [".csv"],
    },
  });

  if (selectedFile) {
    return (
      <div className="flex items-center gap-3 px-3 py-2 mb-2 rounded-xl bg-[#303134] border border-[#3C4043] animate-in slide-in-from-bottom-2 duration-200">
        <div className="w-8 h-8 rounded-lg bg-[#1E1F20] flex items-center justify-center flex-shrink-0">
          {getFileIconForType(selectedFile.type)}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm text-[#E8EAED] truncate">{selectedFile.name}</p>
          <p className="text-xs text-[#9AA0A6]">
            {(selectedFile.size / 1024).toFixed(1)} KB
          </p>
        </div>
        <button
          onClick={(e) => {
            e.stopPropagation();
            onFileSelect(null);
          }}
          className="p-1 rounded-full hover:bg-[#1E1F20] text-[#9AA0A6] hover:text-[#E8EAED] transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    );
  }

  return (
    <div
      {...getRootProps()}
      className={`cursor-pointer transition-all duration-200 ${
        isDragActive ? "scale-105" : ""
      }`}
    >
      <input {...getInputProps()} />
    </div>
  );
}

// Standalone drag overlay component
export function DragOverlay({ isDragActive }: { isDragActive: boolean }) {
  if (!isDragActive) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center">
      <div className="flex flex-col items-center gap-4 p-12 rounded-3xl border-2 border-dashed border-[#8AB4F8] bg-[#303134]/90">
        <Upload className="w-16 h-16 text-[#8AB4F8] animate-bounce" />
        <p className="text-xl font-semibold text-[#E8EAED]">Drop your file here</p>
        <p className="text-sm text-[#9AA0A6]">
          Images, PDFs, Word, Excel, CSV, or text files
        </p>
      </div>
    </div>
  );
}
