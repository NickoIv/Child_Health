/// The thread, as the model is allowed to see it.
///
/// Every question used to be sent alone: «а если не поможет?» arrived with no
/// idea what "it" was, and the parent had to retype the whole question. The
/// chat screen kept the turns for the bubbles and threw them away on the way
/// out.
///
/// Sent as real roles rather than pasted into the question, so the model can
/// tell its own earlier words from the parent's. That distinction is a safety
/// property, not a nicety: the system prompt forbids treating a previous
/// answer as a source, and it can only obey that if the two are separable.
library;

/// One message already in the thread.
class ChatTurn {
  const ChatTurn.parent(this.text) : isParent = true;
  const ChatTurn.assistant(this.text) : isParent = false;

  final String text;
  final bool isParent;

  /// Gemini's vocabulary: the parent is `user`, the assistant is `model`.
  String get role => isParent ? 'user' : 'model';

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// How many past messages travel with a question.
///
/// Three exchanges. Enough for the follow-up that started this, short enough
/// that the retrieved articles stay the bulk of what the model is looking at —
/// they are where the answer has to come from.
const maxHistoryTurns = 6;

/// And how much of one message. An answer runs to a few hundred characters;
/// this only bites on something pathological.
const maxHistoryTurnChars = 1200;

/// The tail of [turns] worth sending.
///
/// Trims to the last [maxHistoryTurns], shortens anything overlong, and drops
/// leading assistant turns — a conversation the model is shown must begin
/// with something the parent said, or the API rejects it outright.
List<ChatTurn> trimHistory(List<ChatTurn> turns) {
  final tail = turns.length <= maxHistoryTurns
      ? List<ChatTurn>.from(turns)
      : turns.sublist(turns.length - maxHistoryTurns);

  while (tail.isNotEmpty && !tail.first.isParent) {
    tail.removeAt(0);
  }

  return [
    for (final turn in tail)
      if (turn.text.trim().isNotEmpty)
        turn.text.length <= maxHistoryTurnChars
            ? turn
            : (turn.isParent
                  ? ChatTurn.parent(_shorten(turn.text))
                  : ChatTurn.assistant(_shorten(turn.text))),
  ];
}

String _shorten(String text) =>
    '${text.substring(0, maxHistoryTurnChars).trimRight()}…';
