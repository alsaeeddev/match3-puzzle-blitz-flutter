import 'dart:math';

// Utility extensions on standard 1D [List].
extension ListExtensions<T> on List<T> {
  // Safely returns the element at [index] or null if out of bounds.
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  // Picks a random element from the list using the provided [random] generator.
  // Throws [StateError] if the list is empty.
  T randomElement(Random random) {
    if (isEmpty) {
      throw StateError('Cannot pick a random element from an empty list.');
    }
    return this[random.nextInt(length)];
  }

  // Returns a new shuffled list, leaving the original list unmodified.
  List<T> shuffledCopy([Random? random]) {
    final copy = List<T>.from(this);
    copy.shuffle(random);
    return copy;
  }
}

// Utility extensions on 2D [List] matrices (e.g., game boards of rows and columns).
extension Matrix2DExtensions<T> on List<List<T>> {
  // Checks whether [row] and [col] represent a valid coordinate inside this matrix.
  bool isValidCoord(int row, int col) {
    if (row < 0 || row >= length) return false;
    final r = this[row];
    return col >= 0 && col < r.length;
  }

  // Safely retrieves the item at ([row], [col]), returning null if out of bounds.
  T? get2DOrNull(int row, int col) {
    if (!isValidCoord(row, col)) return null;
    return this[row][col];
  }

  // Sets the value at ([row], [col]).
  // Throws [RangeError] if the coordinates are out of bounds.
  void set2D(int row, int col, T value) {
    if (!isValidCoord(row, col)) {
      throw RangeError('Coordinate ($row, $col) is out of bounds for matrix ${length}x${this[0].length}');
    }
    this[row][col] = value;
  }

  // Creates a deep mutable copy of the 2D matrix.
  List<List<T>> deepCopy2D() {
    return map((rowList) => List<T>.from(rowList)).toList();
  }

  // Flattens all elements of the 2D grid into an iterable.
  Iterable<T> flatten2D() sync* {
    for (final rowList in this) {
      for (final item in rowList) {
        yield item;
      }
    }
  }

  // Retrieves an entire column at [colIndex] as a new list.
  List<T> columnAt(int colIndex) {
    final column = <T>[];
    for (var r = 0; r < length; r++) {
      if (colIndex >= 0 && colIndex < this[r].length) {
        column.add(this[r][colIndex]);
      }
    }
    return column;
  }

  // Retrieves an entire row at [rowIndex] as a new copy.
  List<T> rowAt(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= length) return <T>[];
    return List<T>.from(this[rowIndex]);
  }
}
