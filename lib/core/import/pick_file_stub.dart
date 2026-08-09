/// What came back: the name, so the screen can say which file, and the text.
typedef PickedFile = ({String name, String text});

/// No picker off the web yet — see `pick_file.dart`. Returning null rather
/// than throwing keeps the screen honest: the button is simply never useful,
/// instead of crashing when it is pressed.
Future<PickedFile?> pickTextFile() async => null;
