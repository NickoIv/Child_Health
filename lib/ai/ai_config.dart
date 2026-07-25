/// Where the assistant sends its requests.
///
/// The Gemini API key never reaches the browser. A web bundle is public, so a
/// key compiled into it is a key given away. Instead the app talks to a small
/// Cloudflare Worker (see `worker/`) that holds the key as a secret and
/// forwards the call.
///
/// Set at build time:
///   `flutter build web --dart-define=AI_PROXY_URL=https://NAME.workers.dev`
///
/// Left empty the assistant stays switched off and the UI explains how to
/// enable it, rather than failing at runtime with a network error.
abstract final class AiConfig {
  static const proxyUrl = String.fromEnvironment('AI_PROXY_URL');

  static bool get isConfigured => proxyUrl.isNotEmpty;

  /// Wall-clock budget for one answer. A parent staring at a spinner needs a
  /// verdict, not patience.
  static const timeout = Duration(seconds: 25);

  /// Cap on the question length, mirrored in the Worker.
  static const maxQuestionLength = 500;
}
