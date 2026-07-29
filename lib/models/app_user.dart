/// Measurement system the parent prefers, per requirement 2.1.
enum UnitSystem {
  metric('metric', 'Метрическая (см, кг)'),
  imperial('imperial', 'Имперская (in, lb)');

  const UnitSystem(this.code, this.label);

  final String code;
  final String label;

  static UnitSystem fromCode(String? code) => UnitSystem.values.firstWhere(
    (u) => u.code == code,
    orElse: () => UnitSystem.metric,
  );
}

class UserSettings {
  const UserSettings({
    this.unitSystem = UnitSystem.metric,
    this.notificationsEnabled = true,
  });

  final UnitSystem unitSystem;
  final bool notificationsEnabled;

  UserSettings copyWith({UnitSystem? unitSystem, bool? notificationsEnabled}) =>
      UserSettings(
        unitSystem: unitSystem ?? this.unitSystem,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
      );

  Map<String, dynamic> toMap() => {
    'unit_system': unitSystem.code,
    'notifications_enabled': notificationsEnabled,
  };

  factory UserSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserSettings();
    return UserSettings(
      unitSystem: UnitSystem.fromCode(map['unit_system'] as String?),
      notificationsEnabled: map['notifications_enabled'] as bool? ?? true,
    );
  }
}

/// Parent profile, collection `users` in the Firestore schema.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.settings = const UserSettings(),
    this.pushTokens = const [],
  });

  final String uid;
  final String email;
  final String displayName;
  final UserSettings settings;

  /// Devices signed in to this account that accepted notifications.
  ///
  /// A list rather than one value: a parent may use the phone and a laptop,
  /// and a reminder that only reaches whichever device registered last is
  /// worse than no reminder at all.
  final List<String> pushTokens;

  AppUser copyWith({
    String? displayName,
    UserSettings? settings,
    List<String>? pushTokens,
  }) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    settings: settings ?? this.settings,
    pushTokens: pushTokens ?? this.pushTokens,
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'display_name': displayName,
    'settings': settings.toMap(),
    'push_tokens': pushTokens,
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    email: map['email'] as String? ?? '',
    displayName: map['display_name'] as String? ?? '',
    settings: UserSettings.fromMap(
      (map['settings'] as Map?)?.cast<String, dynamic>(),
    ),
    pushTokens: (map['push_tokens'] as List?)?.cast<String>() ?? const [],
  );
}
