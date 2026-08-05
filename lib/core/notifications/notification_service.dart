import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../../models/reminder.dart';
import '../l10n/labels.dart';
import 'notification_plan.dart';

/// Reminders the device raises by itself.
///
/// This is the local half of notifications and deliberately separate from
/// `firebase/push_messaging.dart`: push carries messages the server decides to
/// send, this fires what the parent has already planned, and the two can be on
/// at the same time. Nothing here talks to Firebase.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin, this._l10n])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Resolved from the saved language before the first frame, because a
  /// notification channel is named once, when it is created, and the text can
  /// be sitting in the phone's settings long after the app is closed.
  ///
  /// Null in tests and in the offline demo, where nothing is scheduled anyway.
  final AppLocalizations? _l10n;

  /// One channel for everything: a parent who silences "reminders" means all
  /// of them, and three near-identical rows in Android settings would only be
  /// something else to get wrong.
  static const _channelId = 'child_health_reminders';

  String get _channelName => _l10n?.notificationChannelName ?? 'Напоминания';

  String get _channelDescription =>
      _l10n?.notificationChannelDescription ??
      'Прививки, приём лекарств и визиты к врачу';

  bool _ready = false;

  /// A browser can only run a timer while its tab is open, so a schedule set
  /// for tomorrow morning would simply never arrive. On the web the same job
  /// is done by push, which the settings screen already offers.
  static bool get supportsScheduling => !kIsWeb;

  /// Prepares the plugin and the timezone database.
  ///
  /// Safe to call more than once and safe to call on a platform where none of
  /// this works: a failure here must not stop the app from starting.
  Future<void> init() async {
    if (_ready) return;
    try {
      if (supportsScheduling) {
        tz_data.initializeTimeZones();
        // Without this every schedule would be read as UTC, so a 9:00 reminder
        // would arrive at 12:00 in Almaty.
        final local = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(local.identifier));
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          // The launcher icon doubles as the notification icon; the Flutter
          // template ships no separate monochrome asset.
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is not requested here — see [requestPermission].
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );

      _ready = true;
    } catch (e) {
      // An unsupported platform or a missing plugin registration. Reminders
      // still live in Firestore and still show on the planner screen.
      debugPrint('Локальные уведомления недоступны: $e');
    }
  }

  /// Asks for permission, at the moment the parent turns reminders on.
  ///
  /// Returns false when it was refused, so the caller can leave its switch off
  /// rather than promise notifications that will never appear.
  Future<bool> requestPermission() async {
    // Answering "yes" on the web would promise reminders this service cannot
    // deliver there; the caller reads false as "use push instead".
    if (!_ready || !supportsScheduling) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }

      final darwin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (darwin != null) {
        return await darwin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Makes the device hold exactly the notifications [reminders] describe.
  ///
  /// Called with the full list rather than one reminder at a time: scheduling
  /// is keyed by a hash of the reminder id, so re-running this replaces what
  /// was there instead of piling up duplicates.
  Future<void> syncAll(List<Reminder> reminders) async {
    if (!_ready || !supportsScheduling) return;
    for (final reminder in reminders) {
      await syncReminder(reminder);
    }
  }

  /// Reschedules one reminder, cancelling whatever it had before.
  Future<void> syncReminder(Reminder reminder) async {
    if (!_ready || !supportsScheduling) return;
    await cancelReminder(reminder.id);
    for (final slot in slotsFor(reminder, typeLabel: _typeLabel)) {
      await _zonedSchedule(slot);
    }
  }

  /// Drops every notification belonging to [reminderId].
  ///
  /// Covers both slots unconditionally: a reminder that was twice-daily
  /// yesterday and daily today still has an occurrence 1 to clean up.
  Future<void> cancelReminder(String reminderId) async {
    if (!_ready || !supportsScheduling) return;
    for (var occurrence = 0; occurrence < 2; occurrence++) {
      await _plugin.cancel(id: notificationIdFor(reminderId, occurrence));
    }
  }

  /// Clears everything — used when the parent switches reminders off.
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Falls back to the model's own Russian label when no localizations were
  /// handed in, which is the offline demo and the tests.
  String _typeLabel(ReminderType type) =>
      _l10n == null ? type.label : type.localizedLabel(_l10n);

  Future<void> _zonedSchedule(NotificationSlot slot) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    Future<void> attempt(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: slot.id,
      title: slot.title,
      body: slot.body,
      scheduledDate: tz.TZDateTime.from(slot.when, tz.local),
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: switch (slot.repeat) {
        RepeatRule.once => null,
        RepeatRule.daily => DateTimeComponents.time,
        RepeatRule.weekly => DateTimeComponents.dayOfWeekAndTime,
      },
    );

    try {
      // Exact first: a medication reminder that drifts by fifteen minutes is
      // worth less than one that does not.
      await attempt(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      // Android 14 lets the user revoke exact alarms. Approximate timing beats
      // no reminder at all.
      await attempt(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }
}
