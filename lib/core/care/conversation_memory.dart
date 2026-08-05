import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last thing she asked, and nothing else.
///
/// Not a transcript: no answers, no history, no summary, nothing on a server.
/// One question and the moment it was asked, on her own phone — enough to pick
/// a thought back up after the baby interrupted it, and little enough that
/// losing the phone loses nothing worth having.
class LastQuestion {
  const LastQuestion({required this.text, required this.askedAt});

  final String text;
  final DateTime askedAt;

  /// After a day the thread is not a thread any more, it is an old question.
  bool isFreshAt(DateTime now) =>
      now.difference(askedAt) < const Duration(hours: 24) &&
      !askedAt.isAfter(now);
}

const _textKey = 'chat_last_question';
const _timeKey = 'chat_last_question_at';

class ConversationMemory extends Notifier<LastQuestion?> {
  @override
  LastQuestion? build() {
    // Defaults first, disk second: the screen builds on the first frame and
    // must not wait on storage to decide whether to draw the block.
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    // Anything already in memory was set by the parent just now and is
    // newer than what the disk has: a slow read must not overwrite it.
    if (state != null) return;

    final text = prefs?.getString(_textKey);
    final at = DateTime.tryParse(prefs?.getString(_timeKey) ?? '');
    if (text == null || text.isEmpty || at == null) return;
    state = LastQuestion(text: text, askedAt: at);
  }

  Future<void> remember(String question, {DateTime? now}) async {
    final text = question.trim();
    if (text.isEmpty) return;

    final asked = now ?? DateTime.now();
    state = LastQuestion(text: text, askedAt: asked);

    final prefs = await _prefs();
    await prefs?.setString(_textKey, text);
    await prefs?.setString(_timeKey, asked.toIso8601String());
  }

  Future<void> forget() async {
    state = null;
    final prefs = await _prefs();
    await prefs?.remove(_textKey);
    await prefs?.remove(_timeKey);
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No preferences plugin here, or storage refused. The question is still
      // remembered for this run; it simply does not persist.
      return null;
    }
  }
}

final conversationMemoryProvider =
    NotifierProvider<ConversationMemory, LastQuestion?>(
      ConversationMemory.new,
    );
