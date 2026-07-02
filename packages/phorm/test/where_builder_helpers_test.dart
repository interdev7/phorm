import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

void main() {
  const dialect = NoEscapeDialect();

  group('WhereBuilder conditional helpers', () {
    test('addIf runs the builder only when the flag is true', () {
      final included = WhereBuilder().addIf(true, (w) => w.eq('age', 1));
      final excluded = WhereBuilder().addIf(false, (w) => w.eq('age', 1));
      expect(included.isNotEmpty, isTrue);
      expect(excluded.isEmpty, isTrue);
    });

    test('addNotNull runs the builder only for non-null values', () {
      final included =
          WhereBuilder().addNotNull<int>(5, (w, v) => w.eq('age', v));
      final excluded =
          WhereBuilder().addNotNull<int>(null, (w, v) => w.eq('age', v));
      expect(included.isNotEmpty, isTrue);
      expect(excluded.isEmpty, isTrue);
    });

    test('raw tracks used columns via operator detection', () {
      final where = WhereBuilder().raw('age IN (?)', [18]);
      expect(where.usedColumns, contains('age'));
    });
  });

  group('WhereBuilders factory patterns', () {
    test('softDelete builds the right filter per flag combination', () {
      expect(
        WhereBuilders.softDelete(paranoid: false).isEmpty,
        isTrue,
      );
      expect(
        WhereBuilders.softDelete(paranoid: true).build(dialect),
        contains('deleted_at'),
      );
      expect(
        WhereBuilders.softDelete(paranoid: true, onlyDeleted: true)
            .build(dialect),
        contains('IS NOT NULL'),
      );
      expect(
        WhereBuilders.softDelete(paranoid: true, withDeleted: true).isEmpty,
        isTrue,
      );
    });

    test('multiColumnSearch builds an OR group of case-insensitive matches', () {
      final where = WhereBuilders.multiColumnSearch(
        'john',
        const ['first_name', 'last_name'],
      );
      expect(where.args, ['%john%', '%john%']);

      final cs = WhereBuilders.multiColumnSearch(
        'john',
        const ['first_name'],
        caseSensitive: true,
      );
      expect(cs.args, ['%john%']);

      // Empty query or columns produce an empty builder.
      expect(WhereBuilders.multiColumnSearch('', const ['a']).isEmpty, isTrue);
      expect(WhereBuilders.multiColumnSearch('x', const []).isEmpty, isTrue);
    });
  });
}
