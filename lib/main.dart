import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month and weekday names come from intl, not from the widget tree, so the
  // Russian locale data has to be loaded before the first frame.
  await initializeDateFormatting('ru_RU');
  runApp(const ProviderScope(child: ChildHealthApp()));
}
