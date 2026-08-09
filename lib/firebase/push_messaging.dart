import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Web push registration.
///
/// Push on the web needs three things that native does not: the browser's
/// explicit permission, a service worker to receive messages while the tab is
/// closed, and a VAPID key identifying the sender. Any one missing and the
/// token request fails — usually silently, which is why every failure here is
/// turned into a message the settings screen can show.
///
/// The VAPID key is public by design: it is the sender's identity, not a
/// credential. What must stay secret is the service account the Cloudflare
/// Worker uses to send.
abstract final class PushConfig {
  static const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  static bool get isConfigured => vapidKey.isNotEmpty;
}

/// Why registration did not happen. Every case is something the parent can
/// act on or should at least be told about.
enum PushStatus {
  granted('Уведомления включены'),
  denied(
    'Браузер запретил уведомления. Разрешите их в настройках сайта — '
    'значок замка слева от адреса',
  ),
  unsupported('Этот браузер не поддерживает push-уведомления'),
  notConfigured(
    'Push пока не настроен в сборке приложения: не задан ключ VAPID',
  ),
  failed('Не удалось подключить уведомления');

  const PushStatus(this.message);

  final String message;

  bool get isOn => this == PushStatus.granted;
}

class PushRegistration {
  const PushRegistration(this.status, {this.token});

  final PushStatus status;
  final String? token;
}

/// Asks for permission and returns the device token.
///
/// Called only when the parent turns notifications on: a browser prompt that
/// appears unbidden is the fastest way to get permanently denied.
Future<PushRegistration> registerForPush() async {
  if (!PushConfig.isConfigured) {
    return const PushRegistration(PushStatus.notConfigured);
  }

  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();

    final authorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!authorized) {
      return const PushRegistration(PushStatus.denied);
    }

    final token = await messaging.getToken(
      vapidKey: kIsWeb ? PushConfig.vapidKey : null,
    );
    if (token == null || token.isEmpty) {
      return const PushRegistration(PushStatus.failed);
    }

    return PushRegistration(PushStatus.granted, token: token);
  } on UnsupportedError {
    return const PushRegistration(PushStatus.unsupported);
  } catch (_) {
    // A missing service worker, a blocked third-party context, an ad blocker:
    // all surface here, and none of them are worth showing raw.
    return const PushRegistration(PushStatus.failed);
  }
}

/// The token this browser holds right now, or null.
///
/// Never prompts and never asks for anything: it reports what permission has
/// already been given. Called on every start, because a push token is not
/// permanent — a browser rotates it when storage is cleared, when the app is
/// reinstalled to the home screen, or on its own schedule. The copy saved in
/// the profile then points at a device that no longer exists, and reminders
/// go nowhere with nothing to report. Registering once was not enough.
Future<String?> currentPushToken() async {
  if (!PushConfig.isConfigured) return null;

  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }
    return await messaging.getToken(
      vapidKey: kIsWeb ? PushConfig.vapidKey : null,
    );
  } catch (_) {
    return null;
  }
}

/// Stops this device receiving reminders. The token is dropped from the
/// profile by the caller; deleting it here also invalidates it upstream.
Future<void> unregisterFromPush() async {
  try {
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {
    // Already gone, or the browser never granted it. Nothing to undo.
  }
}

/// The signed-in user's ID token, or empty when there is nobody signed in.
///
/// Lives here rather than in the auth repository because it is not part of
/// signing in or out: it is a credential handed to our own Worker so it can
/// check that the person asking it to send an invitation is the person who
/// created that invitation.
Future<String> currentIdToken() async {
  try {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    return await user.getIdToken() ?? '';
  } catch (_) {
    return '';
  }
}
