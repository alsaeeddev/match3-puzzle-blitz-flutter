import 'dart:math';

// A robust wrapper around [Random] supporting deterministic seeds,
// range generation, weighted distributions, and convenience helpers.
class SeededRandom implements Random {
  final int? seed;
  late Random _internalRandom;

  SeededRandom([this.seed]) {
    _internalRandom = seed != null ? Random(seed) : Random();
  }

  // Factory for completely unseeded (system entropy) random generator.
  factory SeededRandom.unseeded() => SeededRandom(null);

  // Resets the generator back to its original seed or a new [newSeed].
  void reset([int? newSeed]) {
    final s = newSeed ?? seed;
    _internalRandom = s != null ? Random(s) : Random();
  }

  @override
  int nextInt(int max) => _internalRandom.nextInt(max);

  @override
  double nextDouble() => _internalRandom.nextDouble();

  @override
  bool nextBool() => _internalRandom.nextBool();

  // Generates a random integer within the closed range [[min], [max]].
  int nextIntInRange(int min, int max) {
    assert(max >= min, 'max must be greater than or equal to min');
    if (min == max) return min;
    return min + _internalRandom.nextInt(max - min + 1);
  }

  // Picks a random item from the given [items] list.
  T itemFrom<T>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'List cannot be empty');
    }
    return items[_internalRandom.nextInt(items.length)];
  }

  // Shuffles a copy of [items] and returns it.
  List<T> shuffle<T>(List<T> items) {
    final copy = List<T>.from(items);
    copy.shuffle(_internalRandom);
    return copy;
  }

  // Returns true with probability [probability] (between 0.0 and 1.0).
  bool chance(double probability) {
    if (probability <= 0.0) return false;
    if (probability >= 1.0) return true;
    return _internalRandom.nextDouble() < probability;
  }
}
