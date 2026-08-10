import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The flag, drawn rather than typed.
///
/// The obvious way to put a flag beside a line of text is the emoji, 🇰🇿, and
/// on this project it is the wrong one: Windows ships no glyphs for the
/// regional-indicator pairs, so Chrome on a Windows machine renders it as the
/// two letters «KZ» in a box. The developer reads this screen on Windows. An
/// image file would work everywhere but means an asset, a licence to check and
/// a second copy at every density.
///
/// So it is painted. Twenty lines of geometry, no dependency, sharp at any
/// size, and correct in both themes because it carries its own colours.
///
/// Simplified deliberately and only where the simplification is invisible at
/// the size this is used: the eagle is a silhouette rather than a portrait,
/// and the hoist ornament is its rhythm rather than its pattern. At sixteen
/// pixels tall the difference cannot be resolved by an eye; what does resolve
/// is the sky, the sun with its rays, the bird beneath it and the gold band on
/// the left, and all four are here.
class KazakhstanFlag extends StatelessWidget {
  const KazakhstanFlag({this.height = 13, super.key});

  final double height;

  /// The flag's own proportions, 1:2. Anything else is a different flag.
  static const ratio = 2.0;

  /// Sky blue and gold, from the state standard.
  static const sky = Color(0xFF00AFCA);
  static const gold = Color(0xFFFEC50C);

  @override
  Widget build(BuildContext context) {
    final size = Size(height * ratio, height);
    return SizedBox.fromSize(
      size: size,
      child: ClipRRect(
        // Just enough to stop a hard corner sitting next to rounded type.
        borderRadius: BorderRadius.circular(2),
        child: CustomPaint(size: size, painter: _FlagPainter()),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  /// The real flag has thirty-two. Kept at thirty-two rather than thinned for
  /// small sizes: below a pixel apart they stop being countable and become the
  /// halo they are meant to read as anyway.
  static const rays = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = KazakhstanFlag.sky,
    );

    final gold = Paint()..color = KazakhstanFlag.gold;
    final center = Offset(w * 0.52, h * 0.42);
    final sunRadius = h * 0.17;

    // Rays first, so the disc covers where they all meet.
    final rayPaint = Paint()
      ..color = KazakhstanFlag.gold
      ..strokeWidth = math.max(0.5, h * 0.035)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _FlagPainter.rays; i++) {
      final angle = i * 2 * math.pi / _FlagPainter.rays;
      final from = center + Offset(math.cos(angle), math.sin(angle)) * sunRadius;
      final to =
          center + Offset(math.cos(angle), math.sin(angle)) * (sunRadius * 1.65);
      canvas.drawLine(from, to, rayPaint);
    }
    canvas.drawCircle(center, sunRadius, gold);

    // The eagle. A thin crescent: thickest at the body in the middle and
    // tapering to a point at each wingtip, which is what a bird at this size
    // is. The first attempt made it a solid wedge as wide as the sun and it
    // read as an arrowhead — worth rendering to a picture and looking at
    // rather than trusting the arithmetic.
    final span = w * 0.26;
    final y = h * 0.82;

    // Wingtips sit above the body, so the outline sags in the middle: that is
    // a bird seen head-on. The version before this arched the other way and
    // came out as a hill under the sun — both attempts are why this file gets
    // rendered to a picture and looked at instead of reasoned about.
    final tipY = y - h * 0.06;
    final eagle = Path()
      ..moveTo(center.dx - span, tipY)
      ..quadraticBezierTo(
        center.dx - span * 0.5,
        y - h * 0.055,
        center.dx,
        y - h * 0.02,
      )
      ..quadraticBezierTo(
        center.dx + span * 0.5,
        y - h * 0.055,
        center.dx + span,
        tipY,
      )
      ..quadraticBezierTo(
        center.dx + span * 0.42,
        y + h * 0.035,
        center.dx,
        y + h * 0.055,
      )
      ..quadraticBezierTo(
        center.dx - span * 0.42,
        y + h * 0.035,
        center.dx - span,
        tipY,
      )
      ..close();
    canvas.drawPath(eagle, gold);

    // The head, which is one dot at this size and the difference between a
    // bird and a smear at any larger one.
    // Overlapping the wings on purpose: sat clear of them it renders as a
    // loose ball above the bird once the flag is bigger than a line of text.
    canvas.drawCircle(
      Offset(center.dx, y - h * 0.035),
      h * 0.025,
      gold,
    );

    // The ornament on the hoist, as its rhythm: a column of small marks in the
    // left ninth, which is the width the standard gives it.
    final bandX = w * 0.045;
    final markWidth = w * 0.021;
    const marks = 6;
    for (var i = 0; i < marks; i++) {
      final cy = h * (0.12 + i * 0.152);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bandX, cy),
            width: markWidth,
            height: h * 0.075,
          ),
          Radius.circular(h * 0.04),
        ),
        gold,
      );
    }
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) => false;
}
