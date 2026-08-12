import 'dart:async';

import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/family_repository.dart';
import 'package:child_health_tracker/features/family/family_section.dart';
import 'package:child_health_tracker/features/family/join_screen.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/family_member.dart';
import 'package:child_health_tracker/models/invite_code.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// An invitation nobody types anything into.
///
/// It started as «отправка приглашения не отправляется, просто тишина» and
/// ended as «может проще убрать почту и оставить ватсап». The address could
/// not simply be deleted — access is granted to the account somebody signs in
/// with — so it is no longer typed instead: she makes a link, sends it in
/// WhatsApp, and his own token supplies the address at the other end.
///
/// What is tested here is the shape of that, and the two limits that make a
/// link safe to send in a chat: one use, and a week.
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
    // Settling is not safe here: one test deliberately leaves a write
    // pending, and pumpAndSettle would wait for it for ever.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pumpJoin(
    WidgetTester tester, {
    required FamilyRepository family,
    required String code,
    String email = fatherEmail,
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyRepositoryProvider.overrideWithValue(family),
          currentEmailProvider.overrideWithValue(email),
          childrenProvider.overrideWith((ref) => Stream.value([child])),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedLocales,
          locale: defaultLocale,
          home: JoinScreen(code: code),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('making one', () {
    testWidgets('the answer stays on the screen instead of sliding away', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      await pumpCard(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.widgetWithText(FilledButton, l.familyInviteLink));
      await tester.pumpAndSettle();

      expect(find.text(l.familyLinkReady), findsOneWidget);

      // A snackbar is gone by now. This is not a snackbar: she put the phone
      // down, picked up the other one, and came back.
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text(l.familyLinkReady), findsOneWidget);
      expect(find.text(l.familyOpenWhatsApp), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, l.familyCopyLink), findsOne);
    });

    testWidgets('the link is printed, not only hidden in a button', (
      tester,
    ) async {
      // A link that exists only inside a button is one she cannot check,
      // cannot read out and cannot see has been made at all.
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      await pumpCard(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.widgetWithText(FilledButton, l.familyInviteLink));
      await tester.pumpAndSettle();

      final printed = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((t) => t.data ?? '')
          .where((t) => t.contains('/join/'));
      expect(printed, isNotEmpty, reason: 'the address is on the screen');
      expect(printed.first, startsWith('https://'));
    });

    testWidgets('a write nobody answers still ends in an answer', (
      tester,
    ) async {
      // The silence itself. A Firestore write on the web completes when the
      // *server* acknowledges it, and with no signal it never completes — so
      // the code after it, including every word the screen was going to say,
      // never ran. The button greyed out and stayed grey.
      final family = _StuckFamilyRepository();
      await pumpCard(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.widgetWithText(FilledButton, l.familyInviteLink));
      await tester.pump();
      await tester.pump();

      expect(find.text(l.familyInviteSending), findsOneWidget);

      await tester.pump(const Duration(seconds: 13));
      await tester.pumpAndSettle();

      expect(find.text(l.familyInviteSending), findsNothing);
      expect(find.text(l.familyLinkFailed), findsOneWidget);
    });
  });

  group('the code', () {
    final at = DateTime(2026, 8, 12, 22, 40);

    test('is long enough not to be guessed and easy enough to read out', () {
      final codes = {for (var i = 0; i < 200; i++) newInviteCode()};
      expect(codes, hasLength(200), reason: 'no two the same');
      for (final code in codes) {
        expect(code, hasLength(16));
        // No i, l, o, 0 or 1: the link is normally tapped, but it is
        // sometimes read down a telephone, and those are the ones that come
        // back wrong when it is.
        expect(RegExp(r'^[a-hjkmnp-z2-9]+$').hasMatch(code), isTrue, reason: code);
      }
    });

    test('lasts a week, and not for ever', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final code = await family.createCode(
        childId: child.id,
        ownerUid: child.parentUid,
        now: at,
      );

      expect(code.isUsableAt(at), isTrue);
      expect(code.isUsableAt(at.add(const Duration(days: 6))), isTrue);
      // A link left in a chat history is a key lying on a table.
      expect(code.isUsableAt(at.add(const Duration(days: 8))), isFalse);
    });

    test('opens once, and never again', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final code = await family.createCode(
        childId: child.id,
        ownerUid: child.parentUid,
        now: at,
      );

      final member = await family.claimCode(
        code: code.code,
        viewerUid: 'father-uid',
        viewerEmail: fatherEmail,
        now: at,
      );
      expect(member.email, fatherEmail);
      expect(member.isAccepted, isTrue);
      expect(member.role, FamilyRole.viewer);
      expect(member.ownerUid, child.parentUid);

      // Forwarded on to a third person, the message opens nothing.
      await expectLater(
        family.claimCode(
          code: code.code,
          viewerUid: 'someone-else',
          viewerEmail: 'someone@example.com',
          now: at,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('and an invented one opens nothing at all', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      expect(await family.codeById('nosuchcode'), isNull);
      await expectLater(
        family.claimCode(
          code: 'nosuchcode',
          viewerUid: 'father-uid',
          viewerEmail: fatherEmail,
          now: at,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('opening one', () {
    testWidgets('says which account it is about to attach to', (tester) async {
      // A phone signed into a second Google account is the ordinary case, not
      // the strange one, and finding out afterwards means asking for a new
      // link.
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final code = await family.createCode(
        childId: child.id,
        ownerUid: child.parentUid,
        now: DateTime.now(),
      );

      await pumpJoin(tester, family: family, code: code.code);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.joinIntro), findsOneWidget);
      expect(find.text(l.joinAs(fatherEmail)), findsOneWidget);
      // And what it does not give, before the button rather than after it.
      expect(find.text(l.joinReadOnly), findsOneWidget);
    });

    testWidgets('accepting writes the membership and says so', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final code = await family.createCode(
        childId: child.id,
        ownerUid: child.parentUid,
        now: DateTime.now(),
      );

      await pumpJoin(tester, family: family, code: code.code);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.widgetWithText(FilledButton, l.joinAccept));
      await tester.pumpAndSettle();

      expect(find.text(l.joinDone), findsOneWidget);

      // `runAsync`, because a widget test runs in fake time and this waits on
      // a stream: awaiting it directly hangs until the ten-minute test
      // timeout, which is exactly what it did.
      final members = await tester.runAsync(
        () => family.watchMembers(child.id).first,
      );
      expect(members!.map((m) => m.email), contains(fatherEmail));
    });

    testWidgets('a spent link says so rather than failing on the button', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final code = await family.createCode(
        childId: child.id,
        ownerUid: child.parentUid,
        now: DateTime.now(),
      );
      await family.claimCode(
        code: code.code,
        viewerUid: 'first-arrival',
        viewerEmail: 'first@example.com',
        now: DateTime.now(),
      );

      await pumpJoin(tester, family: family, code: code.code);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.joinSpent), findsOneWidget);
      expect(find.widgetWithText(FilledButton, l.joinAccept), findsNothing);
    });

    testWidgets('and so does one that never existed', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pumpJoin(tester, family: family, code: 'nosuchcode');
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.joinSpent), findsOneWidget);
    });
  });

  test('every new string exists in all three languages', () async {
    for (final locale in supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      for (final s in [
        l.familyInviteLink,
        l.familyInviteLinkExplain,
        l.familyLinkReady,
        l.familyCopyLink,
        l.familyLinkCopied,
        l.familyLinkFailed,
        l.familyOpenWhatsApp,
        l.familyWhatsAppNotOpened,
        l.joinTitle,
        l.joinIntro,
        l.joinReadOnly,
        l.joinAccept,
        l.joinDone,
        l.joinOpenDiary,
        l.joinSpent,
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
  Future<InviteCode> createCode({
    required String childId,
    required String ownerUid,
    required DateTime now,
  }) => Completer<InviteCode>().future;

  @override
  Future<InviteCode?> codeById(String code) async => null;

  @override
  Future<FamilyMember> claimCode({
    required String code,
    required String viewerUid,
    required String viewerEmail,
    required DateTime now,
  }) => Completer<FamilyMember>().future;

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
