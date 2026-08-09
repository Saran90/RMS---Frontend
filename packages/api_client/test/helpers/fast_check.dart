/// Minimal property-based testing helper — mirrors the pattern in
/// packages/models/test/helpers/fast_check.dart.
///
/// Provides [Arbitrary] generators and the [forAll] assertion runner.

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
            len,
            (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
          ),
        );
      });

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

  /// List of length [[minLen]..[maxLen]].
  static Arbitrary<List<T>> list<T>(
    Arbitrary<T> element, {
    int minLen = 0,
    int maxLen = 5,
  }) => Arbitrary<List<T>>((rng) {
    final range = (maxLen - minLen + 1).clamp(1, maxLen + 1);
    final len = minLen + rng.nextInt(range);
    return List.generate(len, (_) => element.generate(rng));
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
    property(value);
  }
}

/// Async variant of [forAll] for properties that involve `Future`s.
Future<void> forAllAsync<T>(
  Arbitrary<T> arbitrary,
  Future<void> Function(T) property, {
  int iterations = 100,
  int? seed,
}) async {
  final rng = Random(seed);
  for (var i = 0; i < iterations; i++) {
    final value = arbitrary.generate(rng);
    await property(value);
  }
}
