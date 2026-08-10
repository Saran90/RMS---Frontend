/// Helpers for formatting and parsing [DateTime] values as ISO 8601
/// strings while preserving the user's local clock time.
library;

/// Formats [dt] as ISO 8601 with the device's timezone offset so the backend
/// stores the correct instant (e.g. 7:00 PM IST → `…T19:00:00+05:30`).
String toLocalIso8601String(DateTime dt) {
  if (dt.isUtc) return dt.toIso8601String();

  final offset = dt.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final totalMinutes = offset.inMinutes.abs();
  final oh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final om = (totalMinutes % 60).toString().padLeft(2, '0');

  final y = dt.year.toString().padLeft(4, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  final ms = dt.millisecond.toString().padLeft(3, '0');

  return '$y-$mo-${d}T$h:$mi:$s.${ms}$sign$oh:$om';
}

/// Legacy values with a trailing `Z` are real UTC instants from PostgreSQL
/// `timestamptz`; convert to the device local clock for comparisons and UI.
DateTime parseLocalIso8601(String iso) {
  return DateTime.parse(iso).toLocal();
}
