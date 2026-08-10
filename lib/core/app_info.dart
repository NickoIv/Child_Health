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

  /// What the app calls itself in a letter's signature.
  static const appName = 'Дневник ребёнка';

  /// Where feedback goes. The only address in the project that belongs to a
  /// person rather than to a service.
  static const feedbackEmail = 'Nickru777@gmail.com';

  /// Where the developer is, for the about card.
  ///
  /// Empty until he says: a city is a fact about a real person and guessing
  /// one — even from the fact that the app is written for Kazakhstan — would
  /// be inventing it. The row is hidden while this is blank, so filling it in
  /// is a one-line change and nothing ships wrong in the meantime.
  static const location = '';
}
