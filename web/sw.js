// The app, still there when the lift has no signal — and open before she has
// put the phone down.
//
// There was no service worker here at all once, on purpose. Flutter's own is
// cache-first over *everything* including the shell: it serves what it
// installed and looks for a new one afterwards, which is how three deploys
// reached the bucket and never reached a phone.
//
// The answer to that was network-first over everything, which fixed the
// hidden deploy and cost the opening. Nothing was ever served from the cache
// while there was a signal, so every launch re-fetched the whole application:
// 1.3 MB of main.dart.js and 2.2 MB of canvaskit.wasm, four to six seconds of
// blank page on a phone, every time. «Приложение долго открывается.»
//
// So the strategy is per file rather than per app, and the split is the one
// thing that matters here:
//
//   **the shell is network-first, the payload is cache-first.**
//
// The shell — the page itself, flutter_bootstrap.js, version.json — is a few
// kilobytes and is always fetched fresh, so a deploy is noticed within one
// request. The payload — main.dart.js, canvaskit, the assets — is served from
// the cache at once and revalidated behind the reader's back. When the
// revalidation finds a different build the page is *told*, and says so. A
// deploy can therefore still not be hidden: it is either already running or
// there is a line on the screen offering it.

const CACHE = 'child-health-shell-v2';

/// Answered from the cache first, revalidated afterwards.
///
/// Everything here is large and changes only when something is deployed, at
/// which point [announce] tells the page. The rest of the origin — the
/// document, the bootstrap, the manifest — is small enough that fetching it
/// every time costs nothing worth saving.
function isPayload(url) {
  return (
    url.pathname.endsWith('/main.dart.js') ||
    url.pathname.includes('/canvaskit/') ||
    url.pathname.includes('/assets/') ||
    url.pathname.includes('/icons/')
  );
}

self.addEventListener('install', () => {
  // Straight past waiting. A parent should not have to close every tab to get
  // a fix, and there is no migration to do: the cache is filled by use.
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

  event.respondWith(
    isPayload(url) ? cacheFirst(event, request) : networkFirst(request),
  );
});

/// Instant, then honest.
async function cacheFirst(event, request) {
  const cache = await caches.open(CACHE);
  const hit = await cache.match(request, { ignoreSearch: true });

  if (hit) {
    // Behind the reader's back, and the page is only interrupted if the
    // answer is actually a different build.
    event.waitUntil(revalidate(cache, request, hit));
    return hit;
  }

  const fresh = await fetch(request);
  if (keepable(fresh)) {
    cache.put(request, fresh.clone()).catch(() => {});
  }
  return fresh;
}

async function revalidate(cache, request, cached) {
  try {
    const fresh = await fetch(request, { cache: 'no-cache' });
    if (!keepable(fresh)) return;

    // ETag rather than the body: Firebase Hosting sets one on every file, and
    // comparing two megabytes of wasm to find out whether it changed would
    // cost more than fetching it did. Length is the fallback for a host that
    // does not.
    const before = signature(cached);
    const after = signature(fresh);
    await cache.put(request, fresh.clone());
    if (before && after && before !== after) await announce();
  } catch (_) {
    // No signal. What is cached is what was working, and it is already the
    // answer that went back.
  }
}

function signature(response) {
  return (
    response.headers.get('etag') || response.headers.get('content-length') || ''
  );
}

/// Tells every open tab that the copy it is running is one build behind.
///
/// A message rather than a reload: reloading underneath somebody halfway
/// through writing down a feed would lose the feed. The page puts a line at
/// the bottom and she decides.
async function announce() {
  const clients = await self.clients.matchAll({ type: 'window' });
  for (const client of clients) {
    client.postMessage({ type: 'update-ready' });
  }
}

async function networkFirst(request) {
  const cache = await caches.open(CACHE);

  try {
    const fresh = await fetch(request);
    if (keepable(fresh)) {
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

/// Only complete, ordinary answers. A 206 or an opaque response put in a
/// cache is a page that half-loads offline, which is worse than one that says
/// it cannot.
function keepable(response) {
  return !!response && response.status === 200 && response.type === 'basic';
}
