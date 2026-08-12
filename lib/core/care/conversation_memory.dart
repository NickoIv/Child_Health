import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The conversation, kept on her own phone between openings.
///
/// It used to be one question and nothing else — no answers, no thread. That
/// was enough to pick a thought back up after the baby interrupted it, and not
/// enough for the thing a parent actually does: ask on Tuesday «он третью ночь
/// плохо спит», and on Thursday «а сейчас лучше?». The second question was
/// arriving at something with no idea there had been a first.
///
/// Three limits, and they are the whole design:
///
/// **Nothing leaves the phone that was not going anyway.** These turns are
/// replayed into the next request, which is where they came from. Nothing is
/// stored on a server, and clearing it is one tap in the chat window.
///
/// **It forgets.** A week, and six turns. A thread from last month is not
/// context, it is a stranger quoting you back to yourself — and the older it
/// is the more likely the child has changed under it.
///
/// **It is trimmed.** An answer can run to a page; what is kept is its first
/// few hundred characters, which is where the substance of it is.
class ChatTurnRecord {
  const ChatTurnRecord({
    required this.question,
    required this.answer,
    required this.at,
  });

  final String question;
  final String answer;
  final DateTime at;

  bool isFreshAt(DateTime now) =>
      now.difference(at) < conversationLifetime && !at.isAfter(now);

  Map<String, Object?> toJson() => {
    'q': question,
    'a': answer,
    'at': at.toIso8601String(),
  };

  static ChatTurnRecord? fromJson(Map<String, Object?> map) {
    final at = DateTime.tryParse(map['at'] as String? ?? '');
    final question = (map['q'] as String? ?? '').trim();
    if (at == null || question.isEmpty) return null;
    return ChatTurnRecord(
      question: question,
      answer: (map['a'] as String? ?? '').trim(),
      at: at,
    );
  }
}

/// Exchanges kept. Six is two or three real conversations.
const conversationTurnLimit = 6;

/// And how long. After a week a thread is about a different child.
const conversationLifetime = Duration(days: 7);

/// The most of an answer that is worth keeping.
const conversationAnswerMax = 400;

const _key = 'chat_thread';

/// The last question, for the screen that still wants only that.
class LastQuestion {
  const LastQuestion({required this.text, required this.askedAt});

  final String text;
  final DateTime askedAt;

  /// After a day the thread is not a thread any more, it is an old question.
  bool isFreshAt(DateTime now) =>
      now.difference(askedAt) < const Duration(hours: 24) &&
      !askedAt.isAfter(now);
}

class ConversationMemory extends Notifier<List<ChatTurnRecord>> {
  @override
  List<ChatTurnRecord> build() {
    // Defaults first, disk second: the screen builds on the first frame and
    // must not wait on storage to decide whether to draw anything.
    _load();
    return const [];
  }

  /// The newest question, or null — what the older callers ask for.
  LastQuestion? get lastQuestion {
    if (state.isEmpty) return null;
    final newest = state.last;
    return LastQuestion(text: newest.question, askedAt: newest.at);
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    // Anything recorded in this run is newer than the disk.
    if (state.isNotEmpty) return;

    final raw = prefs?.getString(_key);
    if (raw == null || raw.isEmpty) return;
    state = _decode(raw, DateTime.now());
  }

  /// Remembers a question the moment it is asked, before there is an answer.
  ///
  /// Written down first because this is the point at which the phone can be
  /// put down or the tab closed, and a question she asked is worth keeping
  /// even when the reply never arrived.
  Future<void> remember(String question, {DateTime? now}) async {
    final text = question.trim();
    if (text.isEmpty) return;

    final at = now ?? DateTime.now();
    state = [
      ...state.where((t) => t.isFreshAt(at)),
      ChatTurnRecord(question: text, answer: '', at: at),
    ].takeLast(conversationTurnLimit);

    await _save();
  }

  /// Fills in the answer to the question just asked.
  Future<void> answered(String answer, {DateTime? now}) async {
    if (state.isEmpty) return;
    final text = answer.trim();
    if (text.isEmpty) return;

    final newest = state.last;
    state = [
      ...state.take(state.length - 1),
      ChatTurnRecord(
        question: newest.question,
        answer: text.length <= conversationAnswerMax
            ? text
            : '${text.substring(0, conversationAnswerMax)}…',
        at: newest.at,
      ),
    ];

    await _save();
  }

  Future<void> forget() async {
    state = const [];
    final prefs = await _prefs();
    await prefs?.remove(_key);
  }

  Future<void> _save() async {
    final prefs = await _prefs();
    await prefs?.setString(
      _key,
      jsonEncode([for (final turn in state) turn.toJson()]),
    );
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No preferences plugin here, or storage refused. The thread still
      // works for this run; it simply does not persist.
      return null;
    }
  }
}

List<ChatTurnRecord> _decode(String raw, DateTime now) {
  try {
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        ?ChatTurnRecord.fromJson(item as Map<String, Object?>),
    ].where((t) => t.isFreshAt(now)).toList().takeLast(conversationTurnLimit);
  } catch (_) {
    // A key written by an older build — the previous one held a single
    // question under a different name — or half-written. Not worth a crash
    // in the thing that exists to survive being closed.
    return const [];
  }
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}

final conversationMemoryProvider =
    NotifierProvider<ConversationMemory, List<ChatTurnRecord>>(
      ConversationMemory.new,
    );
