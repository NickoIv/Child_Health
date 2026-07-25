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
  });

  final String uid;
  final String email;
  final String displayName;
  final UserSettings settings;

  AppUser copyWith({String? displayName, UserSettings? settings}) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    settings: settings ?? this.settings,
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'display_name': displayName,
    'settings': settings.toMap(),
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    email: map['email'] as String? ?? '',
    displayName: map['display_name'] as String? ?? '',
    settings: UserSettings.fromMap(
      (map['settings'] as Map?)?.cast<String, dynamic>(),
    ),
  );
}
