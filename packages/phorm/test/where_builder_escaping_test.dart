import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

/// Dialect that quotes identifiers like SQLite/Postgres (`"a"."b"`).
class _QuotingDialect extends NoEscapeDialect {
  const _QuotingDialect();

  @override
  String escapeIdentifier(String name) {
    return name.split('.').map((part) => '"$part"').join('.');
  }
}

/// Dialect with Postgres-style numbered placeholders (`$1`, `$2`, ...).
class _NumberedDialect extends _QuotingDialect {
  const _NumberedDialect();

  @override
  String compilePlaceholder(int index) => '\$$index';
}

void main() {
  group('column escaping (structural, no regex)', () {
    test('escapes a plain column', () {
      final where = WhereBuilder().eq('status', 'active');
      expect(where.build(const _QuotingDialect()), '"status" = ?');
    });

    test('escapes dotted (table-qualified) columns per part', () {
      final where = WhereBuilder().eq('users.status', 'active');
      expect(where.build(const _QuotingDialect()), '"users"."status" = ?');
    });

    test('escapes only the column position inside function templates', () {
      final where = WhereBuilder().ilike('name', '%john%');
      expect(
        where.build(const _QuotingDialect()),
        'LOWER("name") LIKE LOWER(?)',
      );
    });

    test('column named like an SQL keyword in the template stays intact', () {
      // Old regex-based escaping replaced every word-boundary match of the
      // column name, so a column literally named LOWER corrupted the
      // surrounding function calls: "LOWER"("LOWER") LIKE "LOWER"(?).
      final where = WhereBuilder().ilike('LOWER', '%x%');
      expect(
        where.build(const _QuotingDialect()),
        'LOWER("LOWER") LIKE LOWER(?)',
      );
    });

    test('column named DATE does not corrupt DATE() wrapper', () {
      final where = WhereBuilder().dateOnlyEq('DATE', DateTime(2024, 1, 15));
      expect(where.build(const _QuotingDialect()), 'DATE("DATE") = ?');
      expect(where.args, ['2024-01-15']);
    });

    test('column named col does not clash with the internal marker', () {
      final where = WhereBuilder().eq('col', 1);
      expect(where.build(const _QuotingDialect()), '"col" = ?');
    });

    test('argument values are never touched by escaping', () {
      // Values travel as bound parameters; even a value that spells out the
      // internal NUL marker or a column name must pass through unchanged.
      const tricky = '\u0000col\u0000 status LOWER(name)';
      final where = WhereBuilder()
          .eq('status', tricky)
          .like('name', '%status%');
      expect(
        where.build(const _QuotingDialect()),
        '"status" = ? AND "name" LIKE ?',
      );
      expect(where.args, [tricky, '%status%']);
    });

    test('NUL bytes are rejected in column names', () {
      expect(
        () => WhereBuilder().eq('\u0000col\u0000', 1),
        throwsArgumentError,
      );
    });

    test('escapes SqlFunctionColumn inner column, not the function', () {
      final column = SqlFunctionColumn<int>(
        'MY_FUNC',
        const PhormColumn('price'),
      );
      final where = WhereBuilder().gt(column, 100);
      expect(where.build(const _QuotingDialect()), 'MY_FUNC("price") > ?');
    });

    test('raw() SQL is emitted verbatim (no escaping)', () {
      final where = WhereBuilder().raw('LENGTH(name) > ?', [3]);
      expect(where.build(const _QuotingDialect()), 'LENGTH(name) > ?');
    });

    test('escaping applies inside nested groups', () {
      final where = WhereBuilder()
          .eq('is_active', 1)
          .orGroup((og) => og.eq('city', 'Sofia').eq('city', 'Plovdiv'));
      expect(
        where.build(const _QuotingDialect()),
        '"is_active" = ? AND ("city" = ? OR "city" = ?)',
      );
    });
  });

  group('numbered placeholders (Postgres-style dialects)', () {
    test('numbers placeholders sequentially across conditions', () {
      final where = WhereBuilder()
          .eq('status', 'active')
          .between('age', 18, 65)
          .inList('role', ['admin', 'mod']);
      expect(
        where.build(const _NumberedDialect()),
        r'"status" = $1 AND "age" BETWEEN $2 AND $3 '
        r'AND "role" IN ($4, $5)',
      );
      expect(where.args, ['active', 18, 65, 'admin', 'mod']);
    });

    test('numbering continues through nested groups and raw()', () {
      final where = WhereBuilder()
          .eq('a', 1)
          .orGroup((og) => og.eq('b', 2).eq('c', 3))
          .raw('LENGTH(name) > ?', [4]);
      expect(
        where.build(const _NumberedDialect()),
        r'"a" = $1 AND ("b" = $2 OR "c" = $3) AND LENGTH(name) > $4',
      );
    });

    test('placeholder question marks inside bound values are not consumed', () {
      final where = WhereBuilder().eq('note', 'really?').eq('id', 7);
      expect(
        where.build(const _NumberedDialect()),
        r'"note" = $1 AND "id" = $2',
      );
      expect(where.args, ['really?', 7]);
    });
  });
}
