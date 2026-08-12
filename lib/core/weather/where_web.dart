import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'place.dart';

/// The browser's own geolocation, asked once and never insisted on.
///
/// Null on every failure there is — refused, unavailable, timed out, or a
/// browser that has no geolocation at all. Refusing must cost her the figures
/// and nothing else: the answer still arrives, and nothing asks again in the
/// same breath.
///
/// A ten-second budget and a cached fix up to half an hour old. A parent
/// asking whether to go outside is standing by the door; a fresh satellite
/// fix she waits thirty seconds for is worse than last half-hour's.
Future<Place?> currentPlace() async {
  final completer = Completer<Place?>();

  void finish(Place? place) {
    if (!completer.isCompleted) completer.complete(place);
  }

  try {
    web.window.navigator.geolocation.getCurrentPosition(
      (web.GeolocationPosition position) {
        finish(
          Place(
            position.coords.latitude.toDouble(),
            position.coords.longitude.toDouble(),
          ).coarse,
        );
      }.toJS,
      ((JSObject _) => finish(null)).toJS,
      web.PositionOptions(
        timeout: 10000,
        maximumAge: 30 * 60 * 1000,
        enableHighAccuracy: false,
      ),
    );
  } catch (_) {
    // No geolocation object at all, or a browser refusing it on an insecure
    // origin. Same outcome as a refusal, and for the same reason.
    finish(null);
  }

  // A belt to the browser's braces: some engines never call the error
  // callback when the permission prompt is dismissed rather than answered.
  return completer.future.timeout(
    const Duration(seconds: 12),
    onTimeout: () => null,
  );
}
