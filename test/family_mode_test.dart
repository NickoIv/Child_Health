import 'package:child_health_tracker/app.dart';
import 'package:child_health_tracker/core/l10n/app_locale.dart';
import 'package:child_health_tracker/data/family_repository.dart';
import 'package:child_health_tracker/data/read_only_repositories.dart';
import 'package:child_health_tracker/features/family/family_section.dart';
import 'package:child_health_tracker/features/family/invite_banner.dart';
import 'package:child_health_tracker/l10n/app_localizations.dart';
import 'package:child_health_tracker/models/child.dart';
import 'package:child_health_tracker/models/development_log.dart';
import 'package:child_health_tracker/models/family_member.dart';
import 'package:child_health_tracker/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A father who can look and cannot touch.
///
/// The tests that matter here are the negative ones. It is easy to give
/// somebody access; the whole feature is whether the access stops exactly
/// where it was supposed to, including on the paths nobody remembered to
/// disable in the interface.
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

  /// The demo stack signs in as the mother; overriding the auth email is how
  /// a test becomes the father without a second Firebase project.
  Future<ProviderContainer> containerFor({
    required String email,
    required FamilyRepository family,
  }) async {
    final container = ProviderContainer.test(
      overrides: [
        familyRepositoryProvider.overrideWithValue(family),
        childrenProvider.overrideWith((ref) => Stream.value([child])),
        currentEmailProvider.overrideWithValue(email),
      ],
    );
    // Held open for the length of the test. A bare `read` on a stream
    // provider subscribes and lets go again, and the invitation stream then
    // never gets as far as its first value.
    container.listen(myInvitationsProvider, (_, _) {});
    return container;
  }

  /// Lets the family stream deliver, then checks. A repository write and the
  /// provider that reflects it are one event-loop turn apart, and awaiting
  /// `.future` only ever returns the *first* value the stream produced.
  Future<void> settleUntil(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('the invitation', () {
    test('starts pending and names the child and the owner', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: 'Dad@Example.com ',
      );

      // The address is normalised once, at the door: everything downstream —
      // the document id, the security rule, the lookup on sign-in — compares
      // it, and a stray capital would silently break all three.
      expect(invitation.email, fatherEmail);
      expect(invitation.role, FamilyRole.viewer);
      expect(invitation.status, InviteStatus.pending);
      expect(invitation.childId, child.id);
      expect(invitation.ownerUid, child.parentUid);
      expect(invitation.acceptedAt, isNull);
      expect(invitation.viewerUid, isEmpty);
    });

    test(
      're-inviting the same address replaces rather than duplicates',
      () async {
        final family = MemoryFamilyRepository();
        addTearDown(family.dispose);

        await family.invite(
          childId: child.id,
          ownerUid: child.parentUid,
          email: fatherEmail,
        );
        await family.invite(
          childId: child.id,
          ownerUid: child.parentUid,
          email: fatherEmail,
        );

        expect(await family.watchMembers(child.id).first, hasLength(1));
      },
    );

    test('accepting records who took it, and nothing else moves', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'father-uid');

      final member = (await family.watchMembers(child.id).first).single;
      expect(member.status, InviteStatus.accepted);
      expect(member.viewerUid, 'father-uid');
      expect(member.acceptedAt, isNotNull);
      // Accepting is not a promotion.
      expect(member.role, FamilyRole.viewer);
      expect(member.ownerUid, child.parentUid);
    });

    test('an address only sees invitations addressed to it', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: 'granny@example.com',
      );

      expect(await family.watchInvitationsFor(fatherEmail).first, hasLength(1));
      expect(
        await family.watchInvitationsFor('nobody@example.com').first,
        isEmpty,
      );
    });

    test('revoking removes the viewer and never the owner', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.revoke(childId: child.id, email: 'DAD@example.com');
      expect(await family.watchMembers(child.id).first, isEmpty);
    });

    test('an address is checked before it is sent anywhere', () {
      expect(looksLikeEmail('dad@example.com'), isTrue);
      expect(looksLikeEmail('  Dad@Example.COM '), isTrue);
      expect(looksLikeEmail('dad'), isFalse);
      expect(looksLikeEmail('dad@example'), isFalse);
      expect(looksLikeEmail('dad @example.com'), isFalse);
      expect(looksLikeEmail(''), isFalse);
    });
  });

  group('the role a session has', () {
    test('is owner until an invitation has actually been accepted', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final container = await containerFor(email: fatherEmail, family: family);

      expect(container.read(accessRoleProvider), FamilyRole.owner);
      expect(container.read(isReadOnlyProvider), isFalse);

      // A pending invitation is an offer, not access.
      await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await settleUntil(
        () => container.read(pendingInvitationsProvider).isNotEmpty,
      );
      expect(container.read(accessRoleProvider), FamilyRole.owner);
      expect(container.read(pendingInvitationsProvider), hasLength(1));
    });

    test('becomes viewer once it is, and follows the owner\'s data', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final container = await containerFor(email: fatherEmail, family: family);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'father-uid');
      await settleUntil(() => container.read(isReadOnlyProvider));

      expect(container.read(accessRoleProvider), FamilyRole.viewer);
      expect(container.read(isReadOnlyProvider), isTrue);
      // The one line that makes reading work: the queries are scoped to
      // whoever owns the record, not to whoever is holding the phone.
      expect(container.read(dataOwnerUidProvider), child.parentUid);
    });

    test('the mother is never made a viewer of her own record', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final container = await containerFor(email: motherEmail, family: family);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'father-uid');
      await settleUntil(
        () => container.read(myInvitationsProvider).value != null,
      );

      // The invitation went to somebody else's address, so it changes nothing
      // about her own session.
      expect(container.read(isReadOnlyProvider), isFalse);
      expect(container.read(accessRoleProvider), FamilyRole.owner);
    });
  });

  group('read-only is a guarantee, not a decoration', () {
    /// Every write the app can make, against the repositories a viewer gets.
    test('every repository refuses every write', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final container = await containerFor(email: fatherEmail, family: family);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'father-uid');
      await settleUntil(() => container.read(isReadOnlyProvider));
      expect(container.read(isReadOnlyProvider), isTrue);

      final log = DevelopmentLog(
        id: '',
        childId: child.id,
        date: DateTime(2026, 8, 5),
        type: LogType.note,
        title: 'x',
      );

      // The interface never offers these. That is not the point: the point is
      // that a route somebody forgets to disable still cannot write.
      final logs = container.read(logRepositoryProvider);
      expect(() => logs.add(log), throwsA(isA<ReadOnlyAccessException>()));
      expect(() => logs.update(log), throwsA(isA<ReadOnlyAccessException>()));
      expect(() => logs.delete('id'), throwsA(isA<ReadOnlyAccessException>()));

      final children = container.read(childRepositoryProvider);
      expect(
        () => children.add(
          parentUid: 'father-uid',
          name: 'x',
          birthDate: DateTime(2026),
          gender: Gender.male,
        ),
        throwsA(isA<ReadOnlyAccessException>()),
      );
      expect(
        () => children.update(child),
        throwsA(isA<ReadOnlyAccessException>()),
      );
      expect(
        () => children.delete(child.id),
        throwsA(isA<ReadOnlyAccessException>()),
      );

      expect(
        () => container.read(photoRepositoryProvider).delete('p'),
        throwsA(isA<ReadOnlyAccessException>()),
      );
      expect(
        () => container.read(reminderRepositoryProvider).delete('r'),
        throwsA(isA<ReadOnlyAccessException>()),
      );
      expect(
        () => container.read(medicalRepositoryProvider).delete('m'),
        throwsA(isA<ReadOnlyAccessException>()),
      );
    });

    test('and lets every read straight through', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final container = await containerFor(email: fatherEmail, family: family);

      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'father-uid');
      await settleUntil(() => container.read(isReadOnlyProvider));

      // Viewing is the entire purpose of the invitation.
      await expectLater(
        container.read(logRepositoryProvider).watchLogs(child.id).first,
        completes,
      );
      await expectLater(
        container
            .read(reminderRepositoryProvider)
            .watchReminders(child.id)
            .first,
        completes,
      );
      await expectLater(
        container.read(photoRepositoryProvider).byId('nope'),
        completes,
      );
    });

    test('an owner keeps a repository that writes', () async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final container = await containerFor(email: motherEmail, family: family);

      expect(container.read(isReadOnlyProvider), isFalse);
      expect(
        container.read(logRepositoryProvider),
        isNot(isA<ReadOnlyLogRepository>()),
      );
    });
  });

  group('on the screen', () {
    final logs = [
      DevelopmentLog(
        id: 'l1',
        childId: child.id,
        date: DateTime(2026, 8, 5, 9),
        type: LogType.feeding,
        title: 'Кормление',
      ),
      DevelopmentLog(
        id: 'l2',
        childId: child.id,
        date: DateTime(2026, 8, 5, 7),
        type: LogType.sleep,
        title: 'Сон',
        durationMinutes: 60,
      ),
    ];

    Future<void> pump(
      WidgetTester tester, {
      required FamilyRepository family,
      String email = motherEmail,
      Locale? locale,
      Size size = const Size(1000, 1800),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyRepositoryProvider.overrideWithValue(family),
            currentEmailProvider.overrideWithValue(email),
            // The in-memory stack seeds one child per signed-in uid, so a
            // viewer — whose queries are scoped to the *owner* — would find
            // nothing. Standing the child up directly is what the security
            // rules do for real: the record is the mother's, and he is
            // allowed to read it.
            childrenProvider.overrideWith((ref) => Stream.value([child])),
            logsProvider.overrideWith((ref) => Stream.value(logs)),
            if (locale != null)
              localeProvider.overrideWith(() => LocaleChoice(locale)),
          ],
          child: const ChildHealthApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a pending invitation greets the father, once', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      await family.invite(
        childId: child.id,
        ownerUid: 'mother-uid',
        email: fatherEmail,
      );

      await pump(tester, family: family, email: fatherEmail);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.familyInviteBanner), findsOneWidget);
      expect(find.text(l.familyAccept), findsOneWidget);
      expect(find.text(l.familyLater), findsOneWidget);

      // Later puts it away without declining: a wrong tap must not cost him
      // an invitation he then has to ask for again.
      await tester.tap(find.text(l.familyLater));
      await tester.pumpAndSettle();
      expect(find.text(l.familyInviteBanner), findsNothing);
    });

    testWidgets('accepting turns the session read-only there and then', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      await family.invite(
        childId: child.id,
        ownerUid: 'mother-uid',
        email: fatherEmail,
      );

      await pump(tester, family: family, email: fatherEmail);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // Before: the six quick actions are live and the header says nothing.
      expect(find.byType(ReadOnlyLock), findsNothing);
      expect(find.text(l.familyRoleViewer), findsNothing);

      await tester.tap(find.text(l.familyAccept));
      await tester.pumpAndSettle();

      // After: the banner is gone, the chip says who he is, and every action
      // that writes is padlocked rather than missing.
      expect(find.text(l.familyInviteBanner), findsNothing);
      expect(find.text(l.familyRoleViewer), findsOneWidget);
      expect(find.byType(ReadOnlyLock), findsWidgets);
    });

    testWidgets('the mother sees no banner and no padlocks', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      await family.invite(
        childId: child.id,
        ownerUid: 'mother-uid',
        email: fatherEmail,
      );

      await pump(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.familyInviteBanner), findsNothing);
      expect(find.byType(ReadOnlyLock), findsNothing);
      // The chip appears once the record is shared, and says which side of it
      // she is on.
      expect(find.text(l.familyRoleOwner), findsWidgets);
    });

    /// A fixed handful of frames rather than `pumpAndSettle`.
    ///
    /// Enough for a `setState` and the input decorator's error animation to
    /// land, and it cannot hang: settling waits for the tree to go completely
    /// quiet, which is a promise about the whole app rather than about this
    /// card.
    Future<void> pumpFrames(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    /// The family card on its own, without walking the settings page to it.
    /// Navigating there through the shell took minutes per test and proved
    /// nothing about the card that this does not.
    Future<void> pumpFamilyCard(
      WidgetTester tester, {
      required FamilyRepository family,
      String email = motherEmail,
    }) async {
      tester.view.physicalSize = const Size(900, 1400);
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
            home: const Scaffold(
              body: SingleChildScrollView(child: FamilySection()),
            ),
          ),
        ),
      );
      await pumpFrames(tester);
    }

    testWidgets('the mother invites and sees it pending', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pumpFamilyCard(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      expect(find.text(l.familyNobody), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, l.familyInviteEmail),
        fatherEmail,
      );
      await tester.tap(find.widgetWithText(FilledButton, l.familyInvite));
      await pumpFrames(tester);

      // «Создано», not «отправлено»: no email leaves the app, and the strip
      // that says so also offers the only way it actually reaches him.
      expect(find.text(l.familyInviteCreated), findsOneWidget);
      expect(find.text(l.familyCopyInvite), findsWidgets);
      expect(find.text(fatherEmail), findsWidgets);
      expect(find.text(l.familyPending), findsOneWidget);
    });

    testWidgets('and nothing in the wording promises an email', (tester) async {
      // He waited for one: «приглашение отправляется но на почту не приходит».
      // Nothing here may say sent, letter or inbox unless it is saying that
      // no letter is coming.
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        expect(l.familyInviteCreated.toLowerCase(), isNot(contains('отправ')));
        expect(l.familyInviteCreated.toLowerCase(), isNot(contains('sent')));
        // And the field says up front what will and will not happen.
        expect(l.familyInviteExplain.trim(), isNotEmpty);
      }
    });

    testWidgets('a typo is caught before an invitation is written', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pumpFamilyCard(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.enterText(
        find.widgetWithText(TextField, l.familyInviteEmail),
        'dad',
      );
      await tester.tap(find.widgetWithText(FilledButton, l.familyInvite));
      await pumpFrames(tester);

      expect(find.text(l.familyEmailInvalid), findsOneWidget);
      // Nothing was written: the list still says there is nobody.
      expect(find.text(l.familyNobody), findsOneWidget);
      expect(find.text(l.familyPending), findsNothing);
    });

    testWidgets('inviting yourself is refused', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);

      await pumpFamilyCard(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // Accepting her own invitation would make the owner a viewer of her own
      // record and lock her out on the next launch.
      await tester.enterText(
        find.widgetWithText(TextField, l.familyInviteEmail),
        motherEmail,
      );
      await tester.tap(find.widgetWithText(FilledButton, l.familyInvite));
      await pumpFrames(tester);

      expect(find.text(l.familySelfInvite), findsOneWidget);
      expect(find.text(l.familyNobody), findsOneWidget);
      expect(find.text(l.familyPending), findsNothing);
    });

    testWidgets('the same address cannot be invited twice', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );

      await pumpFamilyCard(tester, family: family);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.enterText(
        find.widgetWithText(TextField, l.familyInviteEmail),
        fatherEmail,
      );
      await tester.tap(find.widgetWithText(FilledButton, l.familyInvite));
      await pumpFrames(tester);

      expect(find.text(l.familyAlreadyMember), findsOneWidget);
    });

    testWidgets('a viewer cannot invite anyone else', (tester) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final invitation = await family.invite(
        childId: child.id,
        ownerUid: child.parentUid,
        email: fatherEmail,
      );
      await family.accept(invitation, 'demo-uid');

      await pumpFamilyCard(tester, family: family, email: fatherEmail);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      // He sees the family and cannot change it. Passing on access is the
      // owner's to give, not the guest's.
      expect(find.text(l.familyOwnerOnly), findsOneWidget);
      expect(find.widgetWithText(FilledButton, l.familyInvite), findsNothing);
      expect(find.widgetWithText(TextField, l.familyInviteEmail), findsNothing);
      expect(find.text(l.familyAccepted), findsOneWidget);
    });

    testWidgets('the diary offers a padlock instead of a new entry', (
      tester,
    ) async {
      final family = MemoryFamilyRepository();
      addTearDown(family.dispose);
      final invitation = await family.invite(
        childId: child.id,
        ownerUid: 'mother-uid',
        email: fatherEmail,
      );
      await family.accept(invitation, 'demo-uid');

      await pump(tester, family: family, email: fatherEmail);
      final l = await AppLocalizations.delegate.load(defaultLocale);

      await tester.tap(find.byIcon(Icons.auto_stories_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text(l.diaryAddEntry), findsNothing);
      expect(find.text(l.familyReadOnly), findsOneWidget);
      // Nothing to delete with, either.
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byType(ReadOnlyLock), findsWidgets);
    });
  });

  group('the wording', () {
    test('exists in all three languages', () async {
      for (final locale in supportedLocales) {
        final l = await AppLocalizations.delegate.load(locale);
        for (final s in [
          l.familyTitle,
          l.familyInvite,
          l.familyPending,
          l.familyAccepted,
          l.familyAccept,
          l.familyLater,
          l.familyReadOnly,
          l.familyReadOnlyHint,
          l.familyRoleOwner,
          l.familyRoleViewer,
          l.familyInviteBanner,
          l.familyOwnerOnly,
        ]) {
          expect(s.trim(), isNotEmpty, reason: locale.languageCode);
        }
      }
    });

    test('names the two people the way a family does', () async {
      final ru = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(ru.familyRoleOwner, 'Мама');
      expect(ru.familyRoleViewer, 'Папа');

      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.familyRoleOwner, 'Mom');
      expect(en.familyRoleViewer, 'Dad');
    });
  });
}
