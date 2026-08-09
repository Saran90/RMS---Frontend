/// Helpers for formatting and parsing [DateTime] values as ISO 8601
/// strings while preserving the local timezone (instead of converting
/// to UTC).
///
/// Background
/// ----------
/// The reservation flow captures times from the user in the device's
/// local timezone (e.g. 7:00 PM IST). The user expects:
///   * The clock time they picked (7:00 PM) to be what gets stored.
///   * The value to be a valid ISO 8601 string that the backend accepts.
///   * When the backend returns the time, it should display back as 7:00 PM.
///
/// Dart's built-in [DateTime.toIso8601String] behaves as follows:
///   * For a UTC [DateTime] → appends `Z` (e.g. `…19:00:00.000Z`).
///   * For a local [DateTime] → omits any designator
///     (e.g. `…19:00:00.000`), which is rejected by strict validators.
///
/// The previous code in this project called `.toUtc().toIso8601String()`
/// which produced something like `…13:30:00.000Z` — a *real* UTC moment
/// derived from the local time. That meant the stored time was shifted
/// by the timezone offset, so a 7:00 PM local reservation showed up as
/// 1:30 PM (the UTC equivalent) when the backend served it back.
///
/// `toLocalIso8601String` produces a string that:
///   1. Carries the local clock-time the user picked (no shift).
///   2. Is a valid ISO 8601 string that strict backends accept
///      (terminates with `Z`).
///
/// `parseLocalIso8601` is the inverse: it takes a string produced by
/// the helper (or any "local-as-UTC" timestamp with a `Z` designator)
/// and returns a *local* [DateTime] whose clock components match the
/// string. This means the time the backend stored is the time the user
/// sees when it is displayed.
library;

/// Formats [dt] as an ISO 8601 string preserving the local clock time
/// (e.g. `2026-01-27T19:00:00.000Z`).
///
/// The result is a valid ISO 8601 datetime string with a `Z` designator
/// so the backend accepts it, but **the clock time is the local time the
/// user picked — no conversion to actual UTC is performed**.
///
/// If [dt] is already a UTC [DateTime], it is returned unchanged.
String toLocalIso8601String(DateTime dt) {
  if (dt.isUtc) return dt.toIso8601String();

  // Build the ISO string from the local components (year/month/day/hour/
  // minute/second/ms), then append 'Z' as a designator so the value
  // passes strict ISO 8601 validation. We deliberately do NOT call
  // dt.toUtc() because that would shift the clock time by the offset.
  final y = dt.year.toString().padLeft(4, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  final ms = dt.millisecond.toString().padLeft(3, '0');

  return '$y-$mo-${d}T$h:$mi:$s.${ms}Z';
}

/// Parses [iso] — an ISO 8601 string produced by [toLocalIso8601String]
/// (or any string where the local clock time has been encoded with a `Z`
/// designator) — and returns a *local* [DateTime].
///
/// In other words, the returned DateTime's `year`/`month`/`day`/`hour`/
/// `minute`/`second`/`millisecond` components match the components in
/// the string. This is the inverse of [toLocalIso8601String]:
///
/// ```dart
/// final local = DateTime(2026, 1, 27, 19, 0); // 7:00 PM
/// final s = toLocalIso8601String(local);     // "2026-01-27T19:00:00.000Z"
/// final parsed = parseLocalIso8601(s);       // 2026-01-27 19:00:00 (local)
/// ```
DateTime parseLocalIso8601(String iso) {
  // Use Dart's parser for the structural validation, then convert the
  // resulting moment so the *clock* components are preserved on the
  // local timezone. This effectively undoes the `Z` → "local" trick
  // performed in toLocalIso8601String.
  final asUtc = DateTime.parse(iso); // treated as UTC because of 'Z'
  return DateTime(
    asUtc.year,
    asUtc.month,
    asUtc.day,
    asUtc.hour,
    asUtc.minute,
    asUtc.second,
    asUtc.millisecond,
    asUtc.microsecond,
  );
}
