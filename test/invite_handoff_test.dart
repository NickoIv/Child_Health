import 'dart:async';

import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/family_repository.dart';
import 'package:child_health_tracker/features/family/family_section.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/family_member.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «Отправка приглашения не отправляется. Просто тишина и никакой обратной
/// связи.»
///
/// Two separate faults wearing the same face. Nothing was ever emailed —
/// there is no mail key on the Worker and there never was — and what the
/// screen said about that was one strip at the bottom that slid away after
/// three seconds. Anyone who looked up from the phone for a moment saw a
/// button that had greyed out and nothing else.
///
/// So what is tested here is that pressing invite always ends in something
/// that is still on the screen a minute later, and that it carries a way to
/// actually deliver the invitation rather than a report about one.
void main() {
  setUpAll(initializeDateFormatting);

  const motherEmail = 'demo@example.com';
  const fatherEmail = 'dad@example.com';

  final child = Child(
    id: 'c1',
    parentUid: 'mother-uid',
    name: 'Aisha',
    birthDate: DateTime(2025, 8, 2),
    gender: Gender.female,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required FamilyRepository family,
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyRepositoryProvider.overrideWithValue(family),
          currentEmailProvider.overrideWithValue(motherEmail),
          childrenProvider.overrideWith((ref) => Stream.value([child])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedLocales,
          locale: defaultLocale,
          home: const Scaffold(
            body: SingleChildScrollView(child: FamilySection()),
          ),
        ),
      ),
    );
    // Settling is not safe here: one of these tests deliberately leaves a
    // write pending, and pumpAndSettle would wait for it for ever.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> invite(
    WidgetTester tester,
    AppLocalizations l, {
    String email = fatherEmail,
    String phone = '',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextField, l.familyInviteEmail),
      email,
    );
    if (phone.isNotEmpty) {
      await tester.enterText(
        find.widgetWithText(TextField, l.familyInvitePhone),
        phone,
      );
    }
    await tester.tap(find.widgetWithText(FilledButton, l.familyInvite));
  }

  testWidgets('the answer stays on the screen instead of sliding away', (
    tester,
  ) async {
    final family = MemoryFamilyRepository();
    addTearDown(family.dispose);
    await pumpCard(tester, family: family);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await invite(tester, l);
    await tester.pumpAndSettle();

    expect(find.text(l.familyInviteCreated), findsOneWidget);

    // A snackbar is gone by now. This is not a snackbar: she put the phone
    // down, picked up the other one, and came back.
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text(l.familyInviteCreated), findsOneWidget);
    expect(find.text(l.familyOpenWhatsApp), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, l.familyCopyInvite), findsOne);
  });

  testWidgets('a write nobody answers still ends in an answer', (tester) async {
    // The silence itself. A Firestore write on the web completes when the
    // *server* acknowledges it, and with no signal it never completes at all
    // — so the code after it, including every word the screen was going to
    // say, never ran. The button greyed out and stayed grey.
    final family = _StuckFamilyRepository();
    await pumpCard(tester, family: family);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await invite(tester, l);
    await tester.pump();
    await tester.pump();

    // While it is in flight the button says so, rather than only dimming.
    expect(find.text(l.familyInviteSending), findsOneWidget);

    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();

    expect(find.text(l.familyInviteSending), findsNothing);
    expect(find.text(l.familyOpenWhatsApp), findsOneWidget);
  });

  testWidgets('the way to deliver it is offered even when nothing was sent', (
    tester,
  ) async {
    final family = MemoryFamilyRepository();
    addTearDown(family.dispose);
    await pumpCard(tester, family: family);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    // With a number typed, which is the case the Worker would have handled
    // had its WhatsApp account still been authorised. It is offered anyway:
    // an automatic send that reports success and delivers nothing is exactly
    // the failure being fixed here, and she can see her own WhatsApp.
    await invite(tester, l, phone: '+7 700 123 45 67');
    await tester.pumpAndSettle();

    expect(find.text(l.familyOpenWhatsApp), findsOneWidget);
    expect(find.text(l.familyInviteHandoff), findsOneWidget);
    // And the invitation itself exists regardless of what was delivered.
    expect(find.text(l.familyPending), findsOneWidget);
  });

  testWidgets('a refused address produces no panel at all', (tester) async {
    final family = MemoryFamilyRepository();
    addTearDown(family.dispose);
    await pumpCard(tester, family: family);
    final l = await AppLocalizations.delegate.load(defaultLocale);

    await invite(tester, l, email: 'dad');
    await tester.pumpAndSettle();

    expect(find.text(l.familyEmailInvalid), findsOneWidget);
    expect(find.text(l.familyOpenWhatsApp), findsNothing);
  });

  test('every new string exists in all three languages', () async {
    for (final locale in supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      for (final s in [
        l.familyInviteSending,
        l.familyInviteHandoff,
        l.familyOpenWhatsApp,
        l.familyWhatsAppNotOpened,
      ]) {
        expect(s.trim(), isNotEmpty, reason: locale.languageCode);
      }
    }
  });
}

/// A repository whose write is never acknowledged — the lift, the clinic
/// basement, the moment the signal drops between the tap and the reply.
class _StuckFamilyRepository implements FamilyRepository {
  @override
  Future<FamilyMember> invite({
    required String childId,
    required String ownerUid,
    required String email,
  }) => Completer<FamilyMember>().future;

  @override
  Stream<List<FamilyMember>> watchMembers(String childId) =>
      Stream.value(const []);

  @override
  Stream<List<FamilyMember>> watchInvitationsFor(String email) =>
      Stream.value(const []);

  @override
  Future<void> accept(FamilyMember invitation, String viewerUid) async {}

  @override
  Future<void> revoke({required String childId, required String email}) async {}

  @override
  Future<void> thank({
    required String childId,
    required String email,
    required DateTime day,
  }) async {}
}
