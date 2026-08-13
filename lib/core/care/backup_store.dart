import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_reminder.dart';

const _savedKey = 'backup_last_saved_at';
const _snoozeKey = 'backup_reminder_snoozed_until';

/// When a copy was last written, and when she last waved the reminder away.
///
/// Both on her own phone and never in Firestore: they are facts about this
/// device, not about the child, and the whole point of the copy is that it is
/// the thing which does not depend on the server being there.
class BackupState {
  const BackupState({this.lastSaved, this.snoozedUntil});

  final DateTime? lastSaved;
  final DateTime? snoozedUntil;

  BackupState copyWith({DateTime? lastSaved, DateTime? snoozedUntil}) =>
      BackupState(
        lastSaved: lastSaved ?? this.lastSaved,
        snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      );
}

class BackupStore extends Notifier<BackupState> {
  @override
  BackupState build() {
    // Defaults first, disk second: the home screen builds on the first frame
    // and must not wait on storage to decide whether to draw a card.
    _load();
    return const BackupState();
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    if (prefs == null) return;
    // Anything set in this run came from the parent just now and is newer
    // than what the disk has.
    if (state.lastSaved != null || state.snoozedUntil != null) return;
    state = BackupState(
      lastSaved: DateTime.tryParse(prefs.getString(_savedKey) ?? ''),
      snoozedUntil: DateTime.tryParse(prefs.getString(_snoozeKey) ?? ''),
    );
  }

  /// A copy was written. Called from wherever the export actually succeeds,
  /// so the reminder cannot go on asking for something she has just done.
  Future<void> saved(DateTime at) async {
    state = state.copyWith(lastSaved: at);
    final prefs = await _prefs();
    await prefs?.setString(_savedKey, at.toIso8601String());
  }

  Future<void> snooze({DateTime? now}) async {
    final until = (now ?? DateTime.now()).add(backupSnooze);
    // Applied before the write, so the card closes under her finger.
    state = state.copyWith(snoozedUntil: until);
    final prefs = await _prefs();
    await prefs?.setString(_snoozeKey, until.toIso8601String());
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No preferences plugin here, or storage refused. Both facts hold for
      // this run; they simply do not persist.
      return null;
    }
  }
}

final backupStoreProvider =
    NotifierProvider<BackupStore, BackupState>(BackupStore.new);
