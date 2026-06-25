import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

void main() {
  group('SortBuilder', () {
    test('empty builder produces null', () {
      expect(SortBuilder().build(), isNull);
    });

    test('asc / desc chain into a comma-separated ORDER BY', () {
      final s = SortBuilder().asc('name').desc('created_at');
      expect(s.build(), 'name ASC, created_at DESC');
    });

    test('validates column names', () {
      expect(() => SortBuilder().asc('bad name'), throwsArgumentError);
      expect(() => SortBuilder().desc('1col'), throwsArgumentError);
    });

    test('accepts qualified column names', () {
      expect(SortBuilder().asc('users.name').build(), 'users.name ASC');
    });

    test('copy is an independent builder', () {
      final original = SortBuilder().asc('a');
      final copy = original.copy().desc('b');
      expect(original.build(), 'a ASC');
      expect(copy.build(), 'a ASC, b DESC');
    });
  });
}
