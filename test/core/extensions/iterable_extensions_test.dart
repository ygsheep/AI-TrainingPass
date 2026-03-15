import 'package:flutter_test/flutter_test.dart';
import 'package:trainingpass/core/extensions/iterable_extensions.dart';

void main() {
  group('IterableExtensions', () {
    late List<int> testList;

    setUp(() {
      testList = [1, 2, 3, 4, 5];
    });

    group('firstWhereOrNull', () {
      test('should return first element that matches predicate', () {
        expect(testList.firstWhereOrNull((e) => e > 2), equals(3));
      });

      test('should return first element when it matches', () {
        expect(testList.firstWhereOrNull((e) => e == 1), equals(1));
      });

      test('should return null when no element matches', () {
        expect(testList.firstWhereOrNull((e) => e > 10), isNull);
      });

      test('should return null for empty list', () {
        const emptyList = <int>[];
        expect(emptyList.firstWhereOrNull((e) => e > 0), isNull);
      });

      test('should work with string lists', () {
        const strings = ['apple', 'banana', 'cherry'];
        expect(
          strings.firstWhereOrNull((s) => s.startsWith('b')),
          equals('banana'),
        );
      });

      test('should work with object lists', () {
        final people = [
          Person(name: 'Alice', age: 30),
          Person(name: 'Bob', age: 25),
          Person(name: 'Charlie', age: 35),
        ];
        expect(
          people.firstWhereOrNull((p) => p.age > 30)?.name,
          equals('Charlie'),
        );
      });
    });

    group('lastWhereOrNull', () {
      test('should return last element that matches predicate', () {
        expect(testList.lastWhereOrNull((e) => e < 4), equals(3));
      });

      test('should return the element when only one matches', () {
        expect(testList.lastWhereOrNull((e) => e == 3), equals(3));
      });

      test('should return null when no element matches', () {
        expect(testList.lastWhereOrNull((e) => e > 10), isNull);
      });

      test('should return null for empty list', () {
        const emptyList = <int>[];
        expect(emptyList.lastWhereOrNull((e) => e > 0), isNull);
      });

      test('should work with duplicate values', () {
        final list = [1, 2, 2, 3, 2, 4];
        expect(list.lastWhereOrNull((e) => e == 2), equals(2));
        // The value is 2, but it appears at multiple positions
        // lastWhereOrNull returns the value (2), not the position
        expect(list.lastWhereOrNull((e) => e == 2), equals(2));
      });
    });

    group('singleWhereOrNull', () {
      test('should return element when exactly one matches', () {
        expect(testList.singleWhereOrNull((e) => e == 3), equals(3));
      });

      test('should return null when no element matches', () {
        expect(testList.singleWhereOrNull((e) => e > 10), isNull);
      });

      test('should return null when multiple elements match', () {
        expect(testList.singleWhereOrNull((e) => e > 2), isNull);
      });

      test('should return null for empty list', () {
        const emptyList = <int>[];
        expect(emptyList.singleWhereOrNull((e) => e > 0), isNull);
      });

      test('should work with unique values', () {
        final list = [1, 3, 5, 2, 7]; // Only one even number
        expect(list.singleWhereOrNull((e) => e % 2 == 0), equals(2));
      });

      test('should return null for multiple even numbers', () {
        expect(testList.singleWhereOrNull((e) => e % 2 == 0), isNull);
      });
    });

    group('Complex scenarios', () {
      test('firstWhereOrNull vs lastWhereOrNull difference', () {
        final list = [1, 2, 3, 2, 1];
        expect(list.firstWhereOrNull((e) => e == 2), equals(2));
        expect(list.lastWhereOrNull((e) => e == 2), equals(2));
        // But positions differ
        expect(list.indexOf(list.firstWhereOrNull((e) => e == 2)!), equals(1));
        expect(list.lastIndexOf(list.lastWhereOrNull((e) => e == 2)!), equals(3));
      });

      test('chaining operations', () {
        final list = ['a', 'bb', 'ccc', 'dd'];
        final result = list
            .firstWhereOrNull((s) => s.length > 2)
            ?.toUpperCase();
        expect(result, equals('CCC'));
      });

      test('nullable handling', () {
        const list = <int>[];
        final value = list.firstWhereOrNull((e) => e > 0);
        expect(value ?? -1, equals(-1));
      });
    });
  });
}

/// Helper class for testing
class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});
}
