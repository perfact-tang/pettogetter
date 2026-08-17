import '../models/models.dart';

/// Date/calendar helpers shared by the store and the mock service.
///
/// The original app computes day boundaries in the household's time zone using
/// `Calendar`. This port intentionally uses the device-local calendar for day
/// math while still storing `timeZoneIdentifier` for Firestore compatibility.
/// See README for the note on cross-timezone households.

/// Converts Dart's weekday (1=Mon..7=Sun) to the Calendar/Firestore convention
/// used throughout the app (1=Sun..7=Sat).
int swiftWeekday(DateTime date) => (date.weekday % 7) + 1;

/// Local midnight for [date].
DateTime startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// The stable occurrence id for a routine expanded onto [date]:
/// `<routineID>_yyyy-MM-dd`.
String occurrenceID(CareRoutine routine, DateTime date) {
  final d = startOfDay(date);
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${routine.id}_${d.year.toString().padLeft(4, '0')}-$month-$day';
}

/// The due time for [routine] on [day], or null when the routine does not run
/// on that day.
DateTime? dueTimeForRoutine(CareRoutine routine, DateTime day) {
  final runs = routine.frequency == CareRoutineFrequency.daily ||
      routine.weekdays.contains(swiftWeekday(day));
  if (!runs) return null;
  return DateTime(day.year, day.month, day.day, routine.hour, routine.minute);
}
