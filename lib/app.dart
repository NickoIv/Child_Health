import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/l10n/app_locale.dart';
import 'core/router/app_router.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/night_mode.dart';
import 'core/theme/theme_mode.dart';
import 'providers.dart';

class ChildHealthApp extends ConsumerWidget {
  const ChildHealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing is read from either: watching is what keeps the reminder
    // schedule alive for as long as the app is, and what catches a push token
    // the browser rotated while the app was closed.
    ref.watch(notificationSyncProvider);
    ref.watch(pushTokenSyncProvider);

    final locale = ref.watch(localeProvider);
    // `intl` keeps its own idea of the current locale, and every DateFormat
    // built without an explicit one reads it. Set here rather than in main()
    // so that switching language reformats the dates already on screen.
    Intl.defaultLocale = locale.languageCode;

    final night = ref.watch(nightModeProvider);

    return MaterialApp.router(
      // On web this also becomes the browser tab title. Generated rather than
      // fixed, so it follows the chosen language.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Everything the router draws, painted through the red filter when the
      // night screen is on — sheets, dialogs and the full-screen photo viewer
      // included, none of which had to be told about it.
      builder: (context, child) =>
          NightScreen(child: child ?? const SizedBox.shrink()),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // The red filter needs dark pixels under it: run it over the light
      // theme and the screen is a red page rather than red type in the dark.
      themeMode: night ? ThemeMode.dark : ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
