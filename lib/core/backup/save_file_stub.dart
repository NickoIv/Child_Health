/// No download outside the browser yet — see `save_file.dart`.
///
/// False rather than an exception: the screen says it could not save instead
/// of crashing on a button press.
Future<bool> saveTextFile(String filename, String text) async => false;
