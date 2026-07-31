import 'dart:async';

import 'package:child_health_tracker/data/repositories.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/reminder.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reminder store the test drives one child at a time.
///
/// Replays the last list to a new subscriber, the way a Firestore snapshot
/// stream does — otherwise the result would depend on whether the provider
/// happened to subscribe before the test wrote.
class FakeReminderRepository implements ReminderRepository {
  final _controllers = <String, StreamController<List<Reminder>>>{};
  final _last = <String, List<Reminder>>{};

  @override
  Stream<List<Reminder>> watchReminders(String childId) {
    final controller = _controllers.putIfAbsent(
      childId,
      () => StreamController<List<Reminder>>.broadcast(),
    );
    return Stream<List<Reminder>>.multi((listener) {
      final seed = _last[childId];
      if (seed != null) listener.add(seed);
      final subscription = controller.stream.listen(listener.add);
      listener.onCancel = subscription.cancel;
    });
  }

  void emit(String childId, List<Reminder> reminders) {
    _last[childId] = reminders;
    _controllers[childId]?.add(reminders);
  }

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }

  @override
  Future<Reminder> add(Reminder reminder) async => reminder;

  @override
  Future<void> update(Reminder reminder) async {}

  @override
  Future<void> delete(String reminderId) async {}
}

Child child(String id) => Child(
  id: id,
  parentUid: 'parent',
  name: id,
  birthDate: DateTime(2025, 1, 1),
  gender: Gender.female,
);

/// Lets the provider chain — children, then each child's reminders — settle.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

Reminder reminder(String id, String childId) => Reminder(
  id: id,
  childId: childId,
  type: ReminderType.medication,
  title: 'Витамин D',
  scheduledTime: DateTime(2026, 9, 1, 9),
);

void main() {
  late FakeReminderRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeReminderRepository();
    container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(repository),
        childrenProvider.overrideWith(
          (ref) => Stream.value([child('anna'), child('boris')]),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.dispose();
  });

  test('reminders of every child end up in one list', () async {
    final seen = <List<Reminder>>[];
    container.listen(allRemindersProvider, (_, next) {
      final value = next.value;
      if (value != null) seen.add(value);
    }, fireImmediately: true);

    // Let childrenProvider deliver before either child speaks.
    await settle();
    repository.emit('anna', [reminder('a1', 'anna')]);
    await settle();
    repository.emit('boris', [reminder('b1', 'boris')]);
    await settle();

    expect(
      seen.last.map((r) => r.id),
      containsAll(<String>['a1', 'b1']),
      reason: 'напоминания обоих детей должны попадать в расписание',
    );
  });

  test('a child that has not answered yet does not hold up the others', () async {
    List<Reminder>? latest;
    container.listen(allRemindersProvider, (_, next) {
      latest = next.value ?? latest;
    }, fireImmediately: true);

    await settle();
    repository.emit('anna', [reminder('a1', 'anna')]);
    await settle();

    expect(latest?.map((r) => r.id), ['a1']);
  });

  test('one child updating does not duplicate the other', () async {
    List<Reminder>? latest;
    container.listen(allRemindersProvider, (_, next) {
      latest = next.value ?? latest;
    }, fireImmediately: true);

    await settle();
    repository.emit('anna', [reminder('a1', 'anna')]);
    repository.emit('boris', [reminder('b1', 'boris')]);
    await settle();
    // Anna's list is re-sent, as a Firestore snapshot would on any write.
    repository.emit('anna', [reminder('a1', 'anna')]);
    await settle();

    expect(latest?.map((r) => r.id).toList(), ['a1', 'b1']);
  });
}
