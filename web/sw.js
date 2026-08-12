// The app, still there when the lift has no signal.
//
// There was no service worker here on purpose. Flutter's own is cache-first:
// it serves the shell it installed and only looks for a new one afterwards,
// which is how three deploys reached the bucket and never reached a phone.
// It was stripped in deploy.ps1 and the shell went with it, so a parent with
// no signal got a blank page — the diary was in Firestore's local cache and
// there was no app left to read it with.
//
// This is the other strategy, and the difference is the whole point:
//
//   **network first, cache only as a fallback.**
//
// Online, the network answer always wins and is written to the cache on the
// way past. A deploy therefore cannot be hidden: the first request for
// main.dart.js after a release fetches the new one, because the cache is
// never consulted while the network answers. Offline, the last thing that
// worked is served instead of nothing.
//
// It caches only what has actually been fetched from this origin. Firestore,
// Firebase Auth and the Cloudflare worker are all somewhere else and are
// never touched — reads offline come from Firestore's own IndexedDB cache,
// as they always did, and writes queue there and replay on reconnect.

const CACHE = 'child-health-shell-v1';

self.addEventListener('install', () => {
  // Straight to waiting-is-over. A parent should not have to close every tab
  // to get a fix, and there is no migration to do: the cache is filled by use.
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((k) => k.startsWith('child-health-shell-') && k !== CACHE)
          .map((k) => caches.delete(k)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  // Same origin only. Everything that carries the child's data lives
  // elsewhere and must never be answered out of a cache this worker holds.
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  event.respondWith(networkFirst(request));
});

async function networkFirst(request) {
  const cache = await caches.open(CACHE);

  try {
    const fresh = await fetch(request);
    // Only complete, ordinary answers. A 206 or an opaque response put in a
    // cache is a page that half-loads offline, which is worse than one that
    // says it cannot.
    if (fresh && fresh.status === 200 && fresh.type === 'basic') {
      cache.put(request, fresh.clone()).catch(() => {});
    }
    return fresh;
  } catch (error) {
    const hit = await cache.match(request, { ignoreSearch: true });
    if (hit) return hit;

    // A route with nothing cached under its own URL. This is one page behind
    // every address, so the shell answers for all of them — otherwise
    // reopening on /#/diary offline would fail where / succeeds.
    if (request.mode === 'navigate') {
      const shell =
        (await cache.match('index.html', { ignoreSearch: true })) ||
        (await cache.match('./', { ignoreSearch: true })) ||
        (await cache.match('/', { ignoreSearch: true }));
      if (shell) return shell;
    }

    throw error;
  }
}
