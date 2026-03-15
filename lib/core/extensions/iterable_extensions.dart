/// Iterable Extensions
/// Provides utility methods for Iterable collections
extension IterableExtensions<T> on Iterable<T> {
  /// Returns the first element that satisfies the given predicate [test],
  /// or null if no element was found.
  ///
  /// This is a null-safe alternative to [firstWhere] that doesn't throw.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  /// Returns the last element that satisfies the given predicate [test],
  /// or null if no element was found.
  T? lastWhereOrNull(bool Function(T element) test) {
    T? result;
    for (final element in this) {
      if (test(element)) {
        result = element;
      }
    }
    return result;
  }

  /// Returns the single element that satisfies the given predicate [test],
  /// or null if no element was found or more than one element was found.
  T? singleWhereOrNull(bool Function(T element) test) {
    T? result;
    var found = false;
    for (final element in this) {
      if (test(element)) {
        if (found) {
          // More than one element found
          return null;
        }
        result = element;
        found = true;
      }
    }
    return result;
  }
}
