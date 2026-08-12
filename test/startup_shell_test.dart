import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// «Приложение долго открывается.»
///
/// It opened by downloading itself twice. `index.html` fetched the whole
/// 1.3 MB bundle with `cache: 'reload'` and made the application wait behind
/// it before starting — a one-week fix for a hosting misconfiguration, left
/// in permanently — and the service worker was network-first over everything,
/// so the 2.2 MB of canvaskit.wasm came down the wire again on every single
/// launch as well.
///
/// Neither file is reachable from a widget test: they are the page the app
/// arrives in. This reads them, because the alternative is nothing watching
/// them at all, and both regressions are the kind that are invisible until
/// somebody on a phone says the app is slow.
void main() {
  final shell = File('web/index.html').readAsStringSync();
  final worker = File('web/sw.js').readAsStringSync();

  group('the page', () {
    test('does not download the bundle again on every load', () {
      // The line itself may stay — it heals a browser that still holds a
      // year-long immutable entry — but it has to be behind a flag that is
      // set once and read for ever after.
      if (shell.contains("fetch('main.dart.js'")) {
        expect(
          shell.contains('localStorage.getItem('),
          isTrue,
          reason: 'the revalidation must happen once per browser, not once '
              'per launch',
        );
      }
    });

    test('shows something before Flutter paints, and takes it away after', () {
      // Several seconds of blank page reads as broken rather than as loading.
      expect(shell, contains('id="boot"'));
      expect(shell, contains('flutter-first-frame'));
    });

    test('offers a newer build rather than swapping it underneath her', () {
      // The service worker announces; the page shows a line and she decides.
      // Reloading on its own would lose a feed somebody was halfway through
      // writing down.
      expect(shell, contains('update-ready'));
      expect(shell, contains('id="fresh"'));
    });

    test('still unregisters only Flutter\'s own worker', () {
      // It once unregistered every worker on the origin, which took
      // firebase-messaging-sw.js with it on every load and silently undid the
      // whole of background push.
      expect(shell, contains('flutter_service_worker.js'));
      expect(
        shell.contains('getRegistrations().then'),
        isTrue,
        reason: 'the filter is still there',
      );
    });
  });

  group('the service worker', () {
    test('serves the shell from the network, so a deploy cannot hide', () {
      // The property three hidden deploys were paid for. The document, the
      // bootstrap and the manifest are kilobytes; fetching them every time
      // costs nothing worth saving.
      expect(worker, contains('networkFirst'));
      expect(worker, contains('isPayload'));
    });

    test('and serves the heavy, unchanging part from the cache', () {
      expect(worker, contains('cacheFirst'));
      for (final path in const ['main.dart.js', '/canvaskit/', '/assets/']) {
        expect(worker, contains(path), reason: path);
      }
    });

    test('tells the page when what it cached is newer than what is running',
        () {
      expect(worker, contains('revalidate'));
      expect(worker, contains('update-ready'));
    });

    test('never answers for anything that is not this origin', () {
      // Firestore, Auth and the Worker are all somewhere else, and every one
      // of them carries the child's data.
      expect(worker, contains('url.origin !== self.location.origin'));
    });

    test('and a new strategy gets a new cache', () {
      // Same name, new rules, old entries: the payload would be served
      // cache-first out of a store filled under the previous strategy.
      expect(worker, contains("CACHE = 'child-health-shell-v2'"));
    });
  });
}
