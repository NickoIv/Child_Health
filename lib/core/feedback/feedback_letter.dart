import '../app_info.dart';

/// The `mailto:` link the feedback button opens.
///
/// Built here rather than inline so the encoding can be tested: a subject with
/// a space in it and a body with newlines are exactly the two things a
/// hand-written mailto gets wrong, and the failure is a mail client opening
/// with an empty message and no hint why.
///
/// [Uri.encodeComponent] rather than [Uri]'s own query builder, which encodes
/// a space as `+`. Mail clients disagree about `+` in a subject line, and the
/// ones that read it literally put a plus between every word.
String feedbackMailto({
  required String to,
  required String subject,
  required String body,
}) {
  final query =
      'subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}';
  // [Uri.encodeFull] on the address, not encodeComponent: the latter escapes
  // the `@` into `%40`, and a mailto whose address is percent-encoded opens
  // with an empty recipient in several clients. A test caught that.
  return 'mailto:${Uri.encodeFull(to)}?$query';
}

/// What the letter says before she starts typing.
///
/// The build number and nothing else. It is the one fact worth having that
/// she cannot be expected to know, and it is also the whole of what this
/// carries: no child, no dates, no diary, and deliberately not the error log
/// either — that has its own button, above, and its own screenful of text to
/// read first. A feedback form that quietly attaches diagnostics is the thing
/// this app has spent every other decision avoiding.
String feedbackBody(String placeholder) =>
    '$placeholder\n\n—\n${AppInfo.appName} ${AppInfo.version}';
