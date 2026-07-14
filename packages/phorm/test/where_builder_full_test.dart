import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

/// Postgres-like dialect to exercise identifier escaping and `$n` placeholders.
class _PgDialect implements SqlDialect {
  const _PgDialect();
  @override
  String escapeIdentifier(String name) =>
      name.split('.').map((p) => '"$p"').join('.');
  @override
  String compilePlaceholder(int index) => '\$$index';
  @override
  String compileJsonObject(Map<String, String> keyValues) =>
      throw UnimplementedError();
  @override
  String compileJsonArray(String expr, String from) =>
      throw UnimplementedError();
}

void main() {
  group('Comparison operators', () {
    test('eq / ne / gt / gte / lt / lte', () {
      expect(WhereBuilder().eq('a', 1).build(), 'a = ?');
      expect(WhereBuilder().ne('a', 1).build(), 'a != ?');
      expect(WhereBuilder().gt('a', 1).build(), 'a > ?');
      expect(WhereBuilder().gte('a', 1).build(), 'a >= ?');
      expect(WhereBuilder().lt('a', 1).build(), 'a < ?');
      expect(WhereBuilder().lte('a', 1).build(), 'a <= ?');
    });

    test('eq / ne ignore null values', () {
      expect(WhereBuilder().eq('a', null).isEmpty, isTrue);
      expect(WhereBuilder().ne('a', null).isEmpty, isTrue);
    });

    test('bool is converted to 1/0 and DateTime to ISO 8601', () {
      expect(WhereBuilder().eq('active', true).args, [1]);
      expect(WhereBuilder().eq('active', false).args, [0]);
      final dt = DateTime(2024, 1, 2, 3, 4, 5);
      expect(WhereBuilder().eq('at', dt).args, [dt.toIso8601String()]);
    });
  });

  group('Pattern matching', () {
    test('like / notLike / ilike / notIlike / regexp', () {
      expect(WhereBuilder().like('n', '%x%').build(), 'n LIKE ?');
      expect(WhereBuilder().notLike('n', '%x%').build(), 'n NOT LIKE ?');
      expect(
        WhereBuilder().ilike('n', '%x%').build(),
        'LOWER(n) LIKE LOWER(?)',
      );
      expect(
        WhereBuilder().notIlike('n', '%x%').build(),
        'LOWER(n) NOT LIKE LOWER(?)',
      );
      expect(WhereBuilder().regexp('n', '^x').build(), 'n REGEXP ?');
    });

    test('startsWith / endsWith add wildcards', () {
      expect(WhereBuilder().startsWith('n', 'a').args, ['a%']);
      expect(WhereBuilder().endsWith('n', 'a').args, ['%a']);
    });
  });

  group('Length and substr', () {
    test('length operators', () {
      expect(WhereBuilder().lengthEq('n', 3).build(), 'LENGTH(n) = ?');
      expect(WhereBuilder().lengthNe('n', 3).build(), 'LENGTH(n) != ?');
      expect(WhereBuilder().lengthGt('n', 3).build(), 'LENGTH(n) > ?');
      expect(WhereBuilder().lengthGte('n', 3).build(), 'LENGTH(n) >= ?');
      expect(WhereBuilder().lengthLt('n', 3).build(), 'LENGTH(n) < ?');
      expect(WhereBuilder().lengthLte('n', 3).build(), 'LENGTH(n) <= ?');
    });

    test('substr operators', () {
      expect(
        WhereBuilder().substrEq('n', 1, 2, 'ab').build(),
        'SUBSTR(n, ?, ?) = ?',
      );
      expect(
        WhereBuilder().substrLike('n', 1, 2, 'a%').build(),
        'SUBSTR(n, ?, ?) LIKE ?',
      );
      expect(
        WhereBuilder().substrIlike('n', 1, 2, 'a%').build(),
        'LOWER(SUBSTR(n, ?, ?)) LIKE LOWER(?)',
      );
    });
  });

  group('Range and set operations', () {
    test('between / notBetween', () {
      expect(WhereBuilder().between('a', 1, 5).build(), 'a BETWEEN ? AND ?');
      expect(
        WhereBuilder().notBetween('a', 1, 5).build(),
        'a NOT BETWEEN ? AND ?',
      );
    });

    test('inList builds placeholders, empty list yields always-false', () {
      expect(WhereBuilder().inList('a', [1, 2]).build(), 'a IN (?, ?)');
      expect(WhereBuilder().inList('a', const []).build(), '1 = 0');
    });

    test('notInList builds placeholders, empty list is a no-op', () {
      expect(WhereBuilder().notInList('a', [1, 2]).build(), 'a NOT IN (?, ?)');
      expect(WhereBuilder().notInList('a', const []).isEmpty, isTrue);
    });
  });

  group('Null and boolean checks', () {
    test('isNull / isNotNull / isTrue / isFalse', () {
      expect(WhereBuilder().isNull('a').build(), 'a IS NULL');
      expect(WhereBuilder().isNotNull('a').build(), 'a IS NOT NULL');
      expect(WhereBuilder().isTrue('a').build(), 'a = 1');
      expect(WhereBuilder().isFalse('a').build(), 'a = 0');
    });
  });

  group('Date/time helpers', () {
    test('date-only helpers format as yyyy-MM-dd', () {
      final d = DateTime(2024, 3, 9);
      expect(WhereBuilder().dateOnlyEq('c', d).args, ['2024-03-09']);
      expect(WhereBuilder().dateOnlyGt('c', d).build(), 'DATE(c) > ?');
      expect(WhereBuilder().dateOnlyLt('c', d).build(), 'DATE(c) < ?');
      expect(
        WhereBuilder().dateOnlyBetween('c', d, d).build(),
        'DATE(c) BETWEEN ? AND ?',
      );
    });

    test('time-only helper formats as HH:mm:ss', () {
      final t = DateTime(2024, 1, 1, 4, 5, 6);
      expect(WhereBuilder().timeOnlyEq('c', t).args, ['04:05:06']);
    });
  });

  group('Logical groups', () {
    test('andGroup wraps nested conditions in parentheses', () {
      final w = WhereBuilder()
          .eq('country', 'BG')
          .andGroup((g) => g.gt('age', 18).lt('age', 65));
      expect(w.build(), 'country = ? AND (age > ? AND age < ?)');
      expect(w.args, ['BG', 18, 65]);
    });

    test('orGroup uses OR separator', () {
      final w = WhereBuilder()
          .eq('active', 1)
          .orGroup((g) => g.eq('city', 'Sofia').eq('city', 'Plovdiv'));
      expect(w.build(), 'active = ? AND (city = ? OR city = ?)');
      expect(w.args, [1, 'Sofia', 'Plovdiv']);
    });

    test('empty groups are skipped', () {
      expect(WhereBuilder().andGroup((_) {}).isEmpty, isTrue);
      expect(WhereBuilder().orGroup((_) {}).isEmpty, isTrue);
    });
  });

  group('Raw conditions', () {
    test('raw passes through and tracks columns', () {
      final w = WhereBuilder().raw('age > ?', [3]);
      expect(w.build(), 'age > ?');
      expect(w.args, [3]);
      expect(w.isNotEmpty, isTrue);
    });

    test('empty raw is a no-op', () {
      expect(WhereBuilder().raw('').isEmpty, isTrue);
    });

    test('raw throws on placeholder/argument mismatch', () {
      expect(
        () => WhereBuilder().raw('a = ? AND b = ?', [1]),
        throwsArgumentError,
      );
    });
  });

  group('Validation', () {
    test('invalid column name throws ArgumentError', () {
      expect(() => WhereBuilder().eq('bad name', 1), throwsArgumentError);
    });

    test('SqlFunctionColumn is validated through its inner column', () {
      final col = const PhormColumn<String>('name').sqlFunction<int>('LENGTH');
      final w = WhereBuilder().gt(col, 3);
      expect(w.build(), contains('LENGTH(name)'));
    });
  });

  group('Conditional helpers (extension)', () {
    test('eqIfNotNull only adds for non-empty values', () {
      expect(WhereBuilder().eqIfNotNull('n', null).isEmpty, isTrue);
      expect(WhereBuilder().eqIfNotNull('n', '').isEmpty, isTrue);
      expect(WhereBuilder().eqIfNotNull('n', 'x').build(), 'n = ?');
    });

    test('inListIfNotEmpty only adds for non-empty lists', () {
      expect(WhereBuilder().inListIfNotEmpty('n', null).isEmpty, isTrue);
      expect(WhereBuilder().inListIfNotEmpty('n', const []).isEmpty, isTrue);
      expect(WhereBuilder().inListIfNotEmpty('n', [1]).build(), 'n IN (?)');
    });

    test('dateRangeIfProvided handles both / from / to / none', () {
      final a = DateTime(2024);
      final b = DateTime(2025);
      expect(
        WhereBuilder().dateRangeIfProvided('c', a, b).build(),
        'c BETWEEN ? AND ?',
      );
      expect(
        WhereBuilder().dateRangeIfProvided('c', a, null).build(),
        'c >= ?',
      );
      expect(
        WhereBuilder().dateRangeIfProvided('c', null, b).build(),
        'c <= ?',
      );
      expect(
        WhereBuilder().dateRangeIfProvided('c', null, null).isEmpty,
        isTrue,
      );
    });
  });

  group('Utilities', () {
    test('isEmpty / isNotEmpty', () {
      final w = WhereBuilder();
      expect(w.isEmpty, isTrue);
      expect(w.isNotEmpty, isFalse);
      w.eq('a', 1);
      expect(w.isNotEmpty, isTrue);
    });

    test('usedColumns and hasConditionOn track referenced columns', () {
      final w = WhereBuilder().eq('a', 1).gt('b', 2);
      expect(w.usedColumns, containsAll(<String>['a', 'b']));
      expect(w.hasConditionOn('a'), isTrue);
      expect(w.hasConditionOn('zzz'), isFalse);
    });

    test('copy / clone are independent deep copies', () {
      final original = WhereBuilder()
          .eq('a', 1)
          .andGroup((g) => g.gt('b', 2).lt('b', 9));
      final copy = original.copy().eq('c', 3);
      final clone = original.clone();
      expect(original.build(), 'a = ? AND (b > ? AND b < ?)');
      expect(copy.build(), 'a = ? AND (b > ? AND b < ?) AND c = ?');
      expect(clone.build(), original.build());
    });

    test('copy preserves raw conditions and their args', () {
      final original = WhereBuilder().eq('a', 1).raw('LENGTH(name) > ?', [3]);
      final copy = original.copy().eq('c', 5);
      expect(original.build(), 'a = ? AND LENGTH(name) > ?');
      expect(copy.build(), 'a = ? AND LENGTH(name) > ? AND c = ?');
      expect(copy.args, [1, 3, 5]);
    });

    test('debugPrint does not throw', () {
      final w = WhereBuilder()
          .eq('a', 1)
          .raw('LENGTH(name) > ?', [3])
          .andGroup((g) => g.gt('b', 2));
      expect(w.debugPrint, returnsNormally);
    });
  });

  group('Dialect-aware compilation', () {
    test('escapes identifiers and rewrites positional placeholders', () {
      const pg = _PgDialect();
      final w = WhereBuilder().eq('name', 'x').gt('age', 18);
      expect(w.build(pg), r'"name" = $1 AND "age" > $2');
    });

    test('nested group placeholders increment correctly', () {
      const pg = _PgDialect();
      final w = WhereBuilder()
          .eq('a', 1)
          .andGroup((g) => g.eq('b', 2).eq('c', 3));
      expect(w.build(pg), r'"a" = $1 AND ("b" = $2 AND "c" = $3)');
    });
  });
}
