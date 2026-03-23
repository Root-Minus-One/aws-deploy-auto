import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Gemini Chat | AI Assistant",
  description:
    "A powerful AI chat application powered by Google Gemini. Ask questions, analyze documents, images, and more.",
  keywords: ["Gemini", "AI", "Chat", "PDF", "Image Analysis", "Document AI"],
  icons: {
    icon: "/favicon.ico",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="font-inter antialiased bg-[#131314] text-[#E8EAED]">
        {children}
      </body>
    </html>
  );
}
