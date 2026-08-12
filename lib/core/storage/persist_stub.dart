/// Off the web there is no eviction to ask about — see `persist.dart`.
Future<bool> requestPersistentStorage() async => true;

Future<bool> hasPersistentStorage() async => true;
