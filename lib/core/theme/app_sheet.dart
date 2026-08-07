import 'package:flutter/material.dart';

/// Every sheet the app raises, raised the same way.
///
/// Two settings, and both are here because of one bug: on an iPhone with the
/// app on the home screen, «Новое напоминание» came up with a black band across
/// its title and the first line under it unreadable.
///
/// A scroll-controlled sheet grows to whatever its content asks for, and with
/// the keyboard open that is the entire viewport. In a standalone PWA the
/// viewport reaches behind the iOS status bar — which this app declares black —
/// so the top of the sheet was being drawn underneath it.
///
/// [useSafeArea] keeps the sheet clear of the inset the platform reports. The
/// height cap keeps it clear of the one the platform does not: a sheet that
/// stops short of the top cannot be covered whatever the browser claims the
/// viewport is. It reads better besides — a sheet that fills the screen is a
/// page wearing a drag handle.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * maxSheetHeightFraction,
    ),
    builder: builder,
  );
}

/// How much of the screen a sheet is allowed. The remainder is what tells a
/// parent the page is still there underneath, and what no status bar can cover.
const maxSheetHeightFraction = 0.86;
