import 'dart:async';

import 'package:flutter/services.dart';

/// The two ends of a recording, felt and heard rather than read.
///
/// Her eyes are on the child, not on the phone. Opening and closing the
/// microphone have to be distinguishable without looking, so they differ in
/// both channels: a light tap and a rising tone to start, a firmer one and a
/// falling tone to stop.
///
/// On a phone this is the operating system's own haptics and click. The web
/// build has neither — see `cues_web.dart`, which makes its own.
abstract final class VoiceCues {
  static void start() {
    unawaited(HapticFeedback.lightImpact());
    unawaited(SystemSound.play(SystemSoundType.click));
  }

  static void stop() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(SystemSound.play(SystemSoundType.click));
  }
}
