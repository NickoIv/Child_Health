import 'package:child_health_tracker/core/app_info.dart';
import 'package:child_health_tracker/core/feedback/feedback_letter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one link in the app that opens somebody else's program.
///
/// A mailto that encodes badly fails in the least helpful way there is: the
/// mail client opens with an empty message, or with «Дневник+ребёнка» in the
/// subject line, and nobody can tell from the outside which of the two
/// happened. So the encoding is the thing worth pinning down.
void main() {
  group('the mailto link', () {
    test('carries the address, the subject and the body', () {
      final url = feedbackMailto(
        to: 'dev@example.com',
        subject: 'Обратная связь',
        body: 'Здравствуйте',
      );

      expect(url, startsWith('mailto:dev@example.com?'));
      expect(url, contains('subject='));
      expect(url, contains('body='));
    });

    test('encodes a space as %20 and never as a plus', () {
      // Mail clients disagree about `+` in a subject, and the ones that read
      // it literally put a plus between every word.
      final url = feedbackMailto(
        to: 'dev@example.com',
        subject: 'два слова',
        body: 'три слова тут',
      );

      expect(url, isNot(contains('+')));
      expect(url, contains('%20'));
    });

    test('survives the newlines the body is built out of', () {
      final url = feedbackMailto(
        to: 'dev@example.com',
        subject: 's',
        body: 'первая\n\nвторая',
      );

      // Raw newlines in a URL truncate it at the first one in some clients.
      expect(url, isNot(contains('\n')));
      expect(url, contains('%0A'));
    });

    test('does not let an ampersand in the body eat the rest', () {
      final url = feedbackMailto(
        to: 'dev@example.com',
        subject: 's',
        body: 'кнопка «сон & еда» не работает',
      );

      // One ampersand only: the one this function put between the two
      // parameters. An unescaped one in the body would end the body there.
      expect('&'.allMatches(url).length, 1);
    });
  });

  group('what the letter starts with', () {
    test('is her prompt and the build, and nothing else', () {
      final body = feedbackBody('Напишите здесь');

      expect(body, startsWith('Напишите здесь'));
      expect(body, contains(AppInfo.version));
      expect(body, contains(AppInfo.appName));
    });

    test('is exactly that and nothing more', () {
      // Asserted as the whole string rather than by hunting for words: the
      // point is that nothing can be added here quietly. Not the diary, not
      // the child, and deliberately not the error log either — that has its
      // own button and its own screenful of text to read first. A feedback
      // form that silently attaches diagnostics is what this app has spent
      // every other decision avoiding.
      expect(
        feedbackBody('Напишите здесь'),
        'Напишите здесь\n\n—\n${AppInfo.appName} ${AppInfo.version}',
      );
    });
  });

  group('the address', () {
    test('is the one he gave, and it is a real address', () {
      expect(AppInfo.feedbackEmail, contains('@'));
      expect(AppInfo.feedbackEmail.trim(), AppInfo.feedbackEmail);
      expect(AppInfo.feedbackEmail, 'Nickru777@gmail.com');
    });
  });
}
