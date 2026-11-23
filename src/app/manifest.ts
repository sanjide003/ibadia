import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: '/',
    name: 'Ibadia',
    short_name: 'Ibadia',
    description:
      'Ibadia — Fast offline-cached Quran reader with Mushaf & Verse views, Tajweed guide, Prayer Times, Auto-Silent DND, Hijri Calendar, Adhkar, Tasbih, 99 Names, and PDF/PNG export.',
    start_url: '/',
    scope: '/',
    display: 'standalone',
    background_color: '#047857',
    theme_color: '#047857',
    orientation: 'portrait-primary',
    icons: [
      {
        src: '/icons/Icon-192.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'any',
      },
      {
        src: '/icons/Icon-512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'any',
      },
      {
        src: '/icons/Icon-maskable-192.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/Icon-maskable-512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'maskable',
      },
    ],
  };
}
