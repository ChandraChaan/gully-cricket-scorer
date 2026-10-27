// Offline support for Gully Cricket Scorer.
//
// Network first, so a new version shows up as soon as you are online, and
// the cache as a fallback, so the app opens and scores with no signal.
// Matches themselves live in local storage, not here.
'use strict';

const CACHE = 'gully-cricket-scorer-v1';

// Everything the app needs to start, fetched when the worker installs.
const CORE = [
  './',
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/shaders/ink_sparkle.frag',
  'assets/shaders/stretch_effect.frag',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
  // The default text font, which Flutter loads from Google Fonts.
  'https://fonts.gstatic.com/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // One missing file shouldn't stop the rest from being cached.
      await Promise.allSettled(
        CORE.map((url) => cache.add(new Request(url, { cache: 'reload' }))),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) {
        if (key !== CACHE) await caches.delete(key);
      }
      await self.clients.claim();
    })(),
  );
});

function cacheable(request) {
  if (request.method !== 'GET') return false;
  const url = new URL(request.url);
  return (
    url.origin === self.location.origin ||
    url.hostname === 'fonts.gstatic.com'
  );
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (!cacheable(request)) return;
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      try {
        const response = await fetch(request);
        if (response.ok) await cache.put(request, response.clone());
        return response;
      } catch (error) {
        const cached = await cache.match(request, { ignoreSearch: true });
        if (cached) return cached;
        if (request.mode === 'navigate') {
          const shell = await cache.match('index.html');
          if (shell) return shell;
        }
        throw error;
      }
    })(),
  );
});
