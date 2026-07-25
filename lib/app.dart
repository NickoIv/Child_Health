import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ChildHealthApp extends StatelessWidget {
  const ChildHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // On web this value also becomes the browser tab title, overriding the
      // <title> tag in web/index.html.
      title: 'Календарь развития и здоровья ребёнка',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
