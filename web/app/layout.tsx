import React from 'react';
import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/components/AuthProvider';

export const metadata: Metadata = {
  title: 'RETIVA — Platform Skrining Retinopati Diabetik Nasional',
  description: 'Sistem pendukung keputusan klinis skrining retinopati diabetik berbasis kendali mutu citra fundus digital dan pedoman Perdami/ADA 2024.',
  icons: {
    icon: '/logo/logo.png',
    shortcut: '/logo/logo.png',
    apple: '/logo/logo.png',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id">
      <head>
        <link rel="icon" href="/logo/logo.png" type="image/png" />
        <link rel="shortcut icon" href="/logo/logo.png" type="image/png" />
        <link rel="apple-touch-icon" href="/logo/logo.png" />
      </head>
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}

