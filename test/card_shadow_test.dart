import 'dart:io';

import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Why every card in the app was invisible, and the guard against it again.
///
/// The card theme sets `elevation: 0` and a transparent shadow colour — it has
/// to, because Material's elevation shadow on a 22px radius draws a hard grey
/// ring rather than a lift. The consequence nobody noticed for months: a bare
/// `Card` in this app draws *nothing*, so every screen built out of them was
/// white rectangles on a nearly white page. «Блоки сливаются, не видно
/// границ.»
///
/// [AppCard] paints [Warm.shadow] itself. This suite keeps the theme honest
/// and keeps `Card(` out of the feature code so the bug cannot walk back in.
void main() {
  group('the card theme', () {
    test('draws no shadow of its own, on purpose', () {
      final light = AppTheme.light();
      expect(light.cardTheme.elevation, 0);
      expect(light.cardTheme.shadowColor, Colors.transparent);
    });
  });

  group('the shadow that does the work', () {
    test('is two layers in the light, and none in the dark', () {
      final light = Warm.shadow(Brightness.light);
      expect(light.length, 2);
      // The tight one draws the edge, the wide one does the lifting.
      expect(light.first.blurRadius, lessThan(light.last.blurRadius));

      // A shadow under a dark card on a darker page is invisible; there the
      // card colour separates instead.
      expect(Warm.shadow(Brightness.dark), isEmpty);
    });

    test('is faint enough not to read as dirt on a cream page', () {
      for (final layer in Warm.shadow(Brightness.light)) {
        expect(layer.color.a, lessThan(0.12));
      }
    });
  });

  group('and no screen builds a bare Card', () {
    test('anywhere under lib/features', () {
      // A source scan rather than a widget test: the failure is not that a
      // particular card looks wrong, it is that a `Card(` written anywhere in
      // this app is a rectangle with no edge, and that has to be caught at the
      // moment somebody types it.
      final offenders = <String>[];
      final pattern = RegExp(r'(?<![A-Za-z])Card\s*\(');

      for (final entity
          in Directory('lib/features').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (line.trimLeft().startsWith('///')) continue;
          if (!pattern.hasMatch(line)) continue;
          offenders.add('${entity.path}:${i + 1}  ${line.trim()}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Use AppCard, which paints Warm.shadow. A bare Card draws no '
            'shadow in this app:\n${offenders.join('\n')}',
      );
    });
  });
}
