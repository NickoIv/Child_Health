/// Who made this, and which build of it is running.
///
/// Stated once, in code rather than in a comment, so the settings screen, the
/// exported PDF and the page title can never disagree about it. The version is
/// kept in step with `pubspec.yaml` by a test.
abstract final class AppInfo {
  /// The author of the project, as he writes his own name.
  static const author = 'Ивашикин Николай';

  /// Mirrors the `version:` line in pubspec.yaml, without the build number.
  static const version = '1.0.0';
}
