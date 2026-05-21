import 'package:flutter_test/flutter_test.dart';
import 'package:sqflow_core/sqflow_core.dart';

void main() {
  group('WhereBuilder Unit Tests', () {
    test('Should build a basic equal condition', () {
      final where = WhereBuilder().eq('name', 'John');
      expect(where.build(), 'name = ?');
      expect(where.args, ['John']);
    });

    test('Should build complex logical conditions', () {
      final where = WhereBuilder()
          .eq('status', 'active')
          .gt('age', 18)
          .like('email', '%@example.com');
      
      expect(where.build(), 'status = ? AND age > ? AND email LIKE ?');
      expect(where.args, ['active', 18, '%@example.com']);
    });

    test('Should support IN operator', () {
      final where = WhereBuilder().inList('role', ['admin', 'moderator']);
      expect(where.build(), 'role IN (?, ?)');
      expect(where.args, ['admin', 'moderator']);
    });

    test('Should handle copy operations correctly', () {
      final original = WhereBuilder().eq('category', 'books');
      final copy = original.copy().gt('price', 10);

      expect(original.build(), 'category = ?');
      expect(copy.build(), 'category = ? AND price > ?');
      expect(copy.args, ['books', 10]);
    });
  });
}
