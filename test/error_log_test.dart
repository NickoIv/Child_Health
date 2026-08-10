import 'package:child_health_tracker/core/diagnostics/error_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The log she can copy and send, and what it is not allowed to take with it.
///
/// This exists instead of a crash reporter, and the difference is the whole
/// point: nothing is uploaded, the text is on screen before it is copied, and
/// what it contains is bounded on purpose. The tests below are mostly about
/// that last part — this is a child's health record, and a diagnostic that
/// quietly carries an address out of it would be worse than no diagnostic.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('what it refuses to carry', () {
    test('an address is taken out before it is ever stored', () {
      // Not scrubbed on the way out — scrubbed on the way in, so there is
      // nothing to leak from storage either.
      expect(
        scrubbed('failed to invite dad@example.com'),
        'failed to invite <адрес>',
      );
    });

    test('so is anything shaped like a phone number', () {
      expect(scrubbed('whatsapp +7 700 123-45-67 refused'),
          'whatsapp <номер> refused');
      expect(scrubbed('chatId 77001234567 invalid'),
          'chatId <номер> invalid');
    });

    test('and an ordinary message is left alone', () {
      const message = 'RenderBox was not laid out';
      expect(scrubbed(message), message);
    });
  });

  group('what it keeps', () {
    test('the newest first, because that is the one being asked about', () {
      final log = container().read(errorLogProvider.notifier);

      log.record(Exception('первая'), StackTrace.current);
      log.record(Exception('вторая'), StackTrace.current);

      expect(log.state.first.message, contains('вторая'));
      expect(log.state.length, 2);
    });

    test('never more than the limit', () {
      final log = container().read(errorLogProvider.notifier);
      for (var i = 0; i < errorLogLimit + 15; i++) {
        log.record(Exception('ошибка $i'), null);
      }

      expect(log.state.length, errorLogLimit);
      // The oldest fell off the end, not the newest.
      expect(log.state.first.message, contains('ошибка ${errorLogLimit + 14}'));
    });

    test('a message no longer than a person will read', () {
      final log = container().read(errorLogProvider.notifier);
      log.record(Exception('я' * 5000), null);

      expect(
        log.state.first.message.length,
        lessThanOrEqualTo(errorLogMessageMax + 1),
      );
    });
  });

  group('the text she pastes', () {
    test('names the build first, which she is least likely to know', () {
      final log = container().read(errorLogProvider.notifier);
      log.record(Exception('что-то отвалилось'), StackTrace.current);

      final text = log.asText();
      expect(text, startsWith('Дневник ребёнка'));
      expect(text, contains('что-то отвалилось'));
    });

    test('is empty when nothing has broken', () {
      expect(container().read(errorLogProvider.notifier).asText(), '');
    });
  });

  group('and it survives the crash it is describing', () {
    test('by being on disk before the next launch reads it', () async {
      final first = container().read(errorLogProvider.notifier);
      first.record(Exception('до перезагрузки'), null);
      // The write is fire-and-forget at the call site, which is what makes it
      // safe inside an error handler; give it its turn.
      await Future<void>.delayed(Duration.zero);

      final next = container();
      // Reading the provider starts the load from storage.
      next.read(errorLogProvider);
      await Future<void>.delayed(Duration.zero);

      expect(next.read(errorLogProvider).first.message,
          contains('до перезагрузки'));
    });

    test('and clearing it empties both the screen and the disk', () async {
      final log = container().read(errorLogProvider.notifier);
      log.record(Exception('уберётся'), null);
      await log.clear();

      final next = container();
      next.read(errorLogProvider);
      await Future<void>.delayed(Duration.zero);
      expect(next.read(errorLogProvider), isEmpty);
    });
  });
}
