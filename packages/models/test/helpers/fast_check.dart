/// Minimal property-based testing helper inspired by fast-check.
///
/// Provides [Arbitrary] generators and [forAll] assertion helper.
/// Used because a dedicated `fast_check` pub package is not available.

library fast_check;

import 'dart:math';

/// A generator that produces random values of type [T].
class Arbitrary<T> {
  const Arbitrary(this._generate);

  final T Function(Random rng) _generate;

  /// Generate a single sample value.
  T generate(Random rng) => _generate(rng);

  // -------------------------------------------------------------------------
  // Built-in arbitraries
  // -------------------------------------------------------------------------

  /// Non-empty printable ASCII strings (length [minLen]..[maxLen]).
  static Arbitrary<String> string({int minLen = 1, int maxLen = 40}) =>
      Arbitrary<String>((rng) {
        final len =
            minLen + rng.nextInt((maxLen - minLen + 1).clamp(1, maxLen + 1));
        const chars =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
        return String.fromCharCodes(
          List.generate(
              len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
        );
      });

  /// Non-negative doubles up to [max].
  static Arbitrary<double> nonNegativeDouble({double max = 9999.99}) =>
      Arbitrary<double>((rng) => rng.nextDouble() * max);

  /// Doubles in range [[min]..[max]].
  static Arbitrary<double> doubleInRange(double min, double max) =>
      Arbitrary<double>((rng) => min + rng.nextDouble() * (max - min));

  /// Non-negative integers in [0..[max]).
  static Arbitrary<int> nonNegativeInt({int max = 1000}) =>
      Arbitrary<int>((rng) => max == 0 ? 0 : rng.nextInt(max));

  /// Positive integers in [1..[max]].
  static Arbitrary<int> positiveInt({int max = 1000}) =>
      Arbitrary<int>((rng) => 1 + rng.nextInt(max));

  /// Booleans.
  static Arbitrary<bool> boolean() => Arbitrary<bool>((rng) => rng.nextBool());

  /// Pick a random element from [values].
  static Arbitrary<T> oneOf<T>(List<T> values) {
    assert(values.isNotEmpty, 'oneOf requires a non-empty list');
    return Arbitrary<T>((rng) => values[rng.nextInt(values.length)]);
  }

  /// Nullable: with ~15 % probability produce null, otherwise use [inner].
  static Arbitrary<T?> nullable<T>(Arbitrary<T> inner) => Arbitrary<T?>(
      (rng) => rng.nextDouble() < 0.15 ? null : inner.generate(rng));

  /// List of length [[minLen]..[maxLen]].
  static Arbitrary<List<T>> list<T>(
    Arbitrary<T> element, {
    int minLen = 0,
    int maxLen = 5,
  }) =>
      Arbitrary<List<T>>((rng) {
        final range = (maxLen - minLen + 1).clamp(1, maxLen + 1);
        final len = minLen + rng.nextInt(range);
        return List.generate(len, (_) => element.generate(rng));
      });

  /// UTC [DateTime] values in a ~5-year window (2020–2024).
  ///
  /// Precision is milliseconds so that round-trip through ISO-8601 JSON
  /// preserves equality.
  ///
  /// We split into days + intra-day ms to stay within [Random.nextInt]'s
  /// limit of 2^32 per call.
  static Arbitrary<DateTime> dateTime() => Arbitrary<DateTime>((rng) {
        // ~1826 days between 2020-01-01 and 2024-12-31
        const totalDays = 1826;
        const msPerDay = 86400000;
        final dayOffset = rng.nextInt(totalDays); // max 1826 — well within 2^32
        final msInDay = rng.nextInt(msPerDay); // max 86400000 — within 2^32
        final base = DateTime.utc(2020).millisecondsSinceEpoch;
        final ms = base + dayOffset * msPerDay + msInDay;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      });
}

/// Assert [property] holds for [iterations] randomly generated inputs.
///
/// Throws a [TestFailure]-equivalent on the first failing iteration.
void forAll<T>(
  Arbitrary<T> arbitrary,
  void Function(T) property, {
  int iterations = 100,
  int? seed,
}) {
  final rng = Random(seed);
  for (var i = 0; i < iterations; i++) {
    final value = arbitrary.generate(rng);
    property(value); // propagates any expect() failure upward
  }
}
