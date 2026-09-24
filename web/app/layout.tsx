import React from 'react';
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'RETIVA — Platform Skrining Retinopati Diabetik Nasional',
  description: 'Sistem pendukung keputusan klinis skrining retinopati diabetik berbasis kendali mutu citra fundus digital dan pedoman Perdami/ADA 2024.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
