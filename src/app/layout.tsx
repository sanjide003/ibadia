import type { Metadata, Viewport } from 'next';
import {
  Amiri,
  Noto_Sans_Arabic,
  Noto_Sans_Malayalam,
  Plus_Jakarta_Sans,
} from 'next/font/google';
import { IbadiaProvider } from '@/context/IbadiaProvider';
import './globals.css';

const jakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  variable: '--font-jakarta',
  display: 'swap',
});

const amiri = Amiri({
  weight: ['400', '700'],
  subsets: ['arabic'],
  variable: '--font-amiri',
  display: 'swap',
});

const notoMalayalam = Noto_Sans_Malayalam({
  weight: ['400', '500', '600', '700'],
  subsets: ['malayalam'],
  variable: '--font-malayalam',
  display: 'swap',
});

const notoArabic = Noto_Sans_Arabic({
  weight: ['400', '600', '700'],
  subsets: ['arabic'],
  variable: '--font-arabic',
  display: 'swap',
});

export const viewport: Viewport = {
  themeColor: '#047857',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
};

export const metadata: Metadata = {
  title: 'Ibadia — Quran, Prayer Times, Adhkar & 99 Names',
  description:
    'Ibadia (ഇബാദിയ / عبادية): Fast offline-cached Quran reader with Mushaf & Verse modes, Malayalam/English/Arabic translations, Tajweed colors, Prayer Times, Auto-Silent DND, Hijri Calendar, Adhkar, Tasbih, 99 Names, and PDF Export.',
  applicationName: 'Ibadia',
  manifest: '/manifest.webmanifest',
  openGraph: {
    title: 'Ibadia — Quran, Prayer Times, Adhkar & 99 Names',
    description:
      'Read Quran offline in Mushaf & Verse modes with Tajweed, listen to Ayah recitations, track Prayer Times & Auto-Silent DND, Hijri Calendar, Adhkar, Tasbih, and 99 Names of Allah.',
    type: 'website',
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'Ibadia',
  },
  icons: {
    icon: '/favicon.png',
    apple: '/apple-touch-icon.png',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${jakarta.variable} ${amiri.variable} ${notoMalayalam.variable} ${notoArabic.variable}`}
      suppressHydrationWarning
    >
      <body className="antialiased">
        <IbadiaProvider>{children}</IbadiaProvider>
      </body>
    </html>
  );
}
