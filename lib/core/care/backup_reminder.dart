/// When to ask her to keep a copy of the diary.
///
/// The export has been a button in settings, which means it has been used by
/// the people who already knew they wanted it. That is fine while the record
/// also lives on a server; it stops being fine the moment the phone is the
/// only place it lives — a cleared browser is then not an inconvenience but
/// the end of a year of nights.
///
/// So this is the one card on the home screen that is not about the child. It
/// is deliberately rare, and it earns its place by being about the only thing
/// on that screen that cannot be recovered.
library;

/// How long a copy stays fresh enough not to nag about.
///
/// A month. Long enough that nobody sees this twice about the same diary,
/// short enough that what a lost phone costs is measured in weeks.
const backupInterval = Duration(days: 30);

/// How long «позже» holds.
///
/// A week, not a day: waving this away means «not now», and asking again
/// tomorrow is how a card teaches people to stop reading cards.
const backupSnooze = Duration(days: 7);

/// Nothing is asked until there is something to lose.
///
/// Twenty entries is a few days of use. Before that the honest answer to
/// «save a copy» is «of what», and a prompt at that point trains her to
/// dismiss this one without reading it — which is exactly the habit that has
/// to be avoided, because the time it matters is a year from now.
const backupMinEntries = 20;

/// Whether the home screen should ask for a copy.
///
/// Pure, and given everything rather than reading it, so the windows can be
/// tested without waiting a month.
bool backupDue({
  required int entries,
  required DateTime now,
  DateTime? lastBackup,
  DateTime? snoozedUntil,
}) {
  if (entries < backupMinEntries) return false;
  if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
  // Never saved one, and by now there is a diary worth saving.
  if (lastBackup == null) return true;
  return !now.isBefore(lastBackup.add(backupInterval));
}
