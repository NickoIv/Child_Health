import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Asks the browser not to evict this site's storage.
///
/// The local copy of the diary lives in IndexedDB, and browser storage is
/// evictable by default: under pressure for space the browser may clear it,
/// and it is entitled to. For a shopping site that costs a session; here it
/// would cost the offline copy of a child's medical record.
///
/// Granted on heuristics rather than on a prompt in Chrome — an installed
/// app, notifications allowed, a site returned to often — so this is asked
/// once at startup and never insisted on. Firefox prompts. Refusal changes
/// nothing that was working: the data is still on the server and still in the
/// cache, it is simply a cache the browser may reclaim.
Future<bool> requestPersistentStorage() async {
  try {
    final manager = web.window.navigator.storage;
    final granted = await manager.persist().toDart;
    return granted.toDart;
  } catch (_) {
    return false;
  }
}

/// Whether it is already granted, without asking again.
Future<bool> hasPersistentStorage() async {
  try {
    final granted = await web.window.navigator.storage.persisted().toDart;
    return granted.toDart;
  } catch (_) {
    return false;
  }
}
