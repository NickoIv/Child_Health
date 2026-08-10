import 'dart:io';
import 'dart:ui' as ui;

import 'package:child_health_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Temporary: the same block of the app set in each candidate face.
void main() {
  testWidgets('write a preview', (tester) async {
    final dir = Platform.environment['FONTS']!;

    Future<void> load(String family, String file) async {
      final loader = FontLoader(family)
        ..addFont(
          File('$dir/$file').readAsBytes().then(
            (b) => ByteData.view(b.buffer),
          ),
        );
      await loader.load();
    }

    await load('Nunito', 'Nunito.ttf');
    await load('Inter', 'Inter.ttf');
    await load('Manrope', 'Manrope.ttf');
    await load('GolosText', 'GolosText.ttf');
    await load('Onest', 'Onest.ttf');

    const families = [
      ('Nunito', 'сейчас'),
      ('Inter', ''),
      ('Manrope', ''),
      ('GolosText', 'Golos Text'),
      ('Onest', ''),
    ];

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Container(
            width: 900,
            color: Warm.background,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (family, note) in families) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Warm.primaryCard,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: Warm.shadow(Brightness.light),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.isEmpty ? family : '$family — $note',
                          style: TextStyle(
                            fontFamily: family,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Warm.accentInk,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Маус',
                          style: TextStyle(
                            fontFamily: family,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: Warm.ink,
                          ),
                        ),
                        Text(
                          '2 мес. · 20 июня',
                          style: TextStyle(
                            fontFamily: family,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Warm.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Добрый день, Леопард',
                          style: TextStyle(
                            fontFamily: family,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Warm.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ПОСЛЕДНЕЕ КОРМЛЕНИЕ',
                                  style: TextStyle(
                                    fontFamily: family,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: Warm.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '2 ч 10 мин',
                                  style: TextStyle(
                                    fontFamily: family,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                    color: Warm.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: Text(
                                'Колики: что помогает на самом деле. '
                                'Как отличить колики от болезни и что из '
                                'народных методов бесполезно.',
                                style: TextStyle(
                                  fontFamily: family,
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Warm.inkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(Platform.environment['OUT']!)
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
