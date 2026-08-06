import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// The two ends of a recording, on a browser.
///
/// `HapticFeedback` and `SystemSound` are platform channels with nothing on
/// the other end here: on the web they resolve and do nothing at all, which
/// is why holding the button on a phone felt like holding a picture of a
/// button. This makes its own signals.
///
/// The sound is generated rather than fetched — two short tones as data URIs,
/// under two kilobytes together, so there is no request to fail and nothing
/// to preload. Rising to open, falling to close, so the two are told apart
/// with the phone at arm's length and eyes on the child.
///
/// The buzz is a courtesy where it exists. Android answers it; iOS Safari has
/// never implemented the Vibration API and never buzzes, which is why the
/// visual and the sound have to carry this on their own.
abstract final class VoiceCues {
  static void start() => _fire(_startTone, const [24, 30, 24]);

  static void stop() => _fire(_stopTone, const [40]);

  static void _fire(String tone, List<int> pattern) {
    _play(tone);
    _buzz(pattern);
  }

  /// A fresh element each time: replaying one that is still finishing is
  /// silently ignored by Safari, and two blips can overlap when a hold is
  /// short.
  static void _play(String data) {
    try {
      final audio = web.HTMLAudioElement()
        ..src = data
        ..volume = 0.35;
      audio.play().toDart.catchError((Object _) => null);
    } catch (_) {
      // A browser that will not play a data URI without a gesture it can see
      // is not a reason to fail to open the microphone.
    }
  }

  static void _buzz(List<int> pattern) {
    try {
      final navigator = web.window.navigator as _Vibrating;
      navigator.vibrate([for (final ms in pattern) ms.toJS].toJS);
    } catch (_) {
      // No Vibration API here. Every iPhone takes this path.
    }
  }
}

@JS()
extension type _Vibrating._(JSObject _) implements JSObject {
  external JSBoolean vibrate(JSArray<JSNumber> pattern);
}

/// 660 → 990 Hz over 90ms, 8-bit at 11 kHz. Rising: the microphone is open.
const _startTone =
    'data:audio/wav;base64,'
    'UklGRgQEAABXQVZFZm10IBAAAAABAAEAESsAABErAAABAAgAZGF0YeADAACAgYSGiIiG'
    'gXt0bWdlZ214hJKep6upn5B+aVdJQ0VQY3yWr8LMy7+oi2pLMiQlM01ukbLL2drOtpZz'
    'UjgoJjFHZoipxNXYz7mbeVg9LCgxRWOEpcDR1s65nHtaQC8qM0dkhaW/0NPLtpl4WT8w'
    'LTdMaYmowc/RxrCSclQ9MDA9VHGRrsTOzL6miGlNOjE2Rl99nLbHzca0mXtdRTc0PlJu'
    'jKi+ycm8pYlrUD02OkpjgJ21xMjArZN1WkQ5OkZcd5Suv8bBsZl8YEo9O0RYco+ou8TB'
    'spyAZU5APEVXcIymuMG/spyBZlBCPkdZcYylt7+9r5l/ZVBDQUpcdY+nt765q5R7Yk5E'
    'RE5ie5SquLy1pI10XUxESFVqg5uuuLmunIRrV0pGTV50jaOyuLSmkXliUUlKVmmBmKq0'
    'tayahGxZTUpSYneOorC0r6CMdWBSTFBdcIecq7KwpJF7ZlZOUFpsgpensK+llH9qWlBQ'
    'WWp+k6StrqWWgW1cU1JaaX2RoqyspJWCbl5UU1trfpGhqquik4BtXlVVXm2Ak6GpqKCQ'
    'fWtdVlhhcYSVoqimnIx5aFxXW2Z2iJijp6KWhnRlW1lfbHyOnKSknZB/b2JbXGVzhJOf'
    'pKGXiHhpX1xhbHuLmaGim49/cGReX2d1hJOdoZ2UhXZpYV9lcH+NmZ+elop7bWRgZG17'
    'iZWdnpiNf3FnYmRreIaSmp2YjoF0aWRka3aDkJibmI+DdmtlZWt2go6XmpePg3dsZmZs'
    'doKNlpmWjoN3bWhobXeDjZWYlY2Cdm1paW94hI6VlpOLgHVtaWtxe4WPlJWQiH50bWpt'
    'dH2HkJSTjoV7cm1sb3eBipCTkYqCeHFtbnN7hIyRko6HfnZwbnB2f4eOkY+Kg3pzb29z'
    'e4OKj5CMhn53cnByeH+HjI+NiYJ6dHFydnyDio2NioR9d3NydXqBh4yNi4Z/eXRzdHl/'
    'hYqMi4eBe3Z0dHh+hIiLioeCfHd1dXh9goeKioeCfXh2dnh8goaJiYeDfnl3dnh8gYWI'
    'iIaDfnp3d3l9gYWHiIaCfnp4eHp9gYWHh4WCfnt5eXp+gYSGhoSBfnt5eXt+gYSGhYOA'
    'fXt6enx/goSFhIKAfXt6e32AgoSEg4J/fXt7fH6AgoSEg4F+fXx8fX+BgoODgoB+fXx9'
    'foCBgoOCgX9+fX19f4CBgoKBgH9+fX1+f4GBgoGAf35+fn5/gIGBgYGAf35+fn+AgIGB'
    'gYB/f35+f3+AgIGAgH9/f39/f4CAgICAgH9/f39/gICAgICAf39/f39/gICAgIB/f39/'
    'f3+AgICAgIB/f39/f4CAgA==';

/// 880 → 520 Hz over 110ms. Falling: it closed, and nothing is listening.
const _stopTone =
    'data:audio/wav;base64,'
    'UklGRuAEAABXQVZFZm10IBAAAAABAAEAESsAABErAAABAAgAZGF0YbwEAACAgYSGhYF7'
    'dG5scHmFk52gnI99aVlRVWR7lq26uaqPblA8N0Rhh63J1c2xh1o2IyY/Z5W919zLqHxQ'
    'MCMsSHKew9jYw59zSi4lMVB6pMfY1b6YbUYtJzVVf6jI19K6lGpFLSk4WIGpyNbQt5Jp'
    'RS8rOlmBqMbUz7eTa0cxLDpYfqXD0s65lm9MNC05VHqgv8/OvJt1UTgvN1BzmbnMzr+i'
    'flk+MTVKao+xx87EqohkRjQ0Q2CEpsDMx7OUcFA6Mz1Vdpm2yMq7oH9dQzY5S2iKqsDJ'
    'wq2PbU88N0FZeZq1xca5n39fRjk7S2eHpbzGwa6SclVBOkFVcpKuwMS7pYhpTj88R158'
    'mrPBwrWdf2JLPj9NZYOftcG+sJd6Xkk/QlFqh6K2wLysk3dcSUBEVG2Jo7a+uqqSdlxK'
    'QkZWbomitb24qZJ3XktDR1Zsh6Cyu7iqlHphTkVHVGmDnK+5uKyYf2ZTSEdSZX2Wqra3'
    'rpyFbVhLSE9gdo6jsrexoo11YFBJTVpuhZustLOoln9pV0xLVGV6kaSws62finRgUkxQ'
    'XG+FmamxsKeWgWxbUE5VZHeMn6yxraCPemZYUFFaan2Roq2vqZuJdWNWUVNeboKUpKyt'
    'ppiGc2JWUlZhcYSWpKurpJaEcmJXVFdicoSVo6qqopWEc2NZVVhjcYOToaipopaGdWZb'
    'V1licICQnqaoo5iJeWpeWFlgbXyMmqOmo5uNfm9iW1peaXeGlJ+kpJ2ShHVoX1tdZXF/'
    'jpqhpKCXi3xvZF1cYWt4hpOcoqGckoV3a2JeX2VwfYqVnaGfmI2BdGlhX2Fpc4CMl52f'
    'nZWKfnJoYmBja3WCjZednpuTiX1yaWNiZWx2go2Wm52ak4l+c2pkY2ZsdoGLlJqbmZOK'
    'f3VsZmRmbHV/iZKYmpmTi4J4b2lmZ2tyfIaOlZiYlY6FfHNsaGdqcHiBipGWmJaQiYB3'
    'cGpoaW10fIWNk5aWk42FfXVuamlrcHd/h46TlZSQioN7dG5ra21yeYGIjpKUko+Jgnp0'
    'b2xsb3R6gYiOkZORjoiBenRwbW1wdHqBh4yQkZCNiIJ8dnFvbnB0eX+Fi46QkI2Jg314'
    'c3BvcXR4foOIjI+PjYqFgHp2cnFxc3d7gIaKjY6Ni4eDfnl1cnJzdXl9goeKjI2MiYWB'
    'fHh1c3N0d3p/g4eKi4yKiISAfHh2dHR1eHt/g4aJiouJh4SAfHl3dXV2eHt/goWIiYqJ'
    'h4SBfXp4dnZ3eHt+gYSHiImIh4SBfnx5eHd3eHt9gIOFh4iHh4WCgH17eXh4eXp8foGD'
    'hYaHhoWDgX99e3p5eXp7fX+Bg4WGhoWEg4F/fXt6enp7fH1/gYOEhYWFhIKBf318e3t7'
    'e3x+f4GCg4SEhIOCgX9+fXx7e3x8fn+AgYKDg4ODgoGAf359fHx8fX1+f4CBgoKDgoKB'
    'gH9+fn19fX19fn+AgIGCgoKCgYGAf39+fn19fn5+f4CAgYGBgYGBgIB/f35+fn5+fn9/'
    'gICAgYGBgYCAgH9/f39/f39/f39/gICAgICAgICAgH9/f39/f39/f3+AgICAgICAgICA'
    'gH9/f39/f39/f3+AgICAgICAgICAgH9/f39/f39/f38=';
