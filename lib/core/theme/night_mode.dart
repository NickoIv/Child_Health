import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_mode.dart';

/// The deep red screen, for the feeds that happen in the dark.
///
/// Not a darker theme — the app already has one. This removes the blue and
/// green light entirely, which is the thing that actually matters at four in
/// the morning: red light leaves night vision intact, so a mother can put the
/// phone down and still see the cot, and it is the least likely to wake the
/// child whose face is thirty centimetres from the screen.
///
/// It is a filter over the whole app rather than a third palette, and that is
/// the point: every screen, every sheet, every chart and every screen written
/// after today is covered by it, and no colour anywhere in the app has to know
/// this mode exists.
enum NightPreference {
  off,
  auto,
  on;

  static NightPreference fromName(String? name) =>
      NightPreference.values.firstWhere(
        (p) => p.name == name,
        orElse: () => defaultNight,
      );
}

/// Off until she asks for it.
///
/// Automatic would be the kind thing to guess and the wrong thing to do: a
/// screen that turns dark red on its own at nine in the evening reads as a
/// fault, and the first thing a parent does with a fault is stop trusting the
/// app that produced it.
const defaultNight = NightPreference.off;

const _storageKey = 'night_mode';

/// How much of the white is left.
///
/// A quarter is taken out on top of the red: the filter alone still leaves a
/// full-brightness screen, and brightness is half of what wakes a baby.
const nightDim = 0.75;

class NightChoice extends Notifier<NightPreference> {
  NightChoice([this._initial = defaultNight]);

  final NightPreference _initial;

  @override
  NightPreference build() {
    _load();
    return _initial;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved == null) return;
      // Anything set since build() was called is newer than the disk.
      if (state != _initial) return;
      state = NightPreference.fromName(saved);
    } catch (_) {
      // No preferences plugin here, or storage refused.
    }
  }

  Future<void> set(NightPreference value) async {
    // Applied first: the screen should change under the finger rather than
    // after a round trip to disk.
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, value.name);
    } catch (_) {
      // Kept for this run even if it could not be stored.
    }
  }
}

final nightPreferenceProvider =
    NotifierProvider<NightChoice, NightPreference>(NightChoice.new);

/// Whether the red screen is on right now.
///
/// [now] is injectable so the automatic window can be tested without waiting
/// for nightfall. The window is the one the dark theme already uses — there is
/// no second definition of night in this app.
bool nightModeActive(NightPreference preference, {DateTime? now}) =>
    switch (preference) {
      NightPreference.off => false,
      NightPreference.on => true,
      NightPreference.auto => isNightAt(now ?? DateTime.now()),
    };

final nightModeProvider = Provider<bool>(
  (ref) => nightModeActive(ref.watch(nightPreferenceProvider)),
);

/// Luminance in, red out.
///
/// The standard luminance weights, so a colour keeps the brightness it had
/// rather than whatever its red channel happened to be — a green «сохранено»
/// tick and a violet chip stay as different from each other as their weights
/// make them, instead of both going black.
///
/// Green and blue are zeroed outright. Halving them instead would look
/// gentler and defeat the purpose: it is the short wavelengths that wake a
/// child and cost a parent her night vision.
List<double> nightMatrix({double dim = nightDim}) => <double>[
  0.2126 * dim, 0.7152 * dim, 0.0722 * dim, 0, 0,
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0,
  0, 0, 0, 1, 0,
];

ColorFilter nightFilter({double dim = nightDim}) =>
    ColorFilter.matrix(nightMatrix(dim: dim));

/// Wraps the whole app in [nightFilter] while the mode is on.
///
/// Placed at the very top of the tree, above the router: a sheet, a dialog and
/// a full-screen photo are all painted through it, and none of them had to be
/// told about it.
class NightScreen extends ConsumerWidget {
  const NightScreen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(nightModeProvider)) return child;
    return ColorFiltered(colorFilter: nightFilter(), child: child);
  }
}
