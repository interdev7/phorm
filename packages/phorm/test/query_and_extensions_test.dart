import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

class _User extends Model {
  _User(this.id, {this.age = 7, this.name});
  final int id;
  final int age;
  final String? name;
  @override
  Map<String, dynamic> toJson() => {'id': id, 'age': age, 'name': name};
}

/// Fake database exposing only what query building needs (dialect + tables).
class _FakeDb implements PhormDatabase {
  _FakeDb(this._tables);
  final List<Table> _tables;

  @override
  SqlDialect get dialect => const NoEscapeDialect();
  @override
  List<Table> get tables => _tables;
  @override
  PhormLogger? get logger => null;
  @override
  int get isolateThreshold => 1000;
  @override
  Stream<String> get changeStream => const Stream.empty();

  @override
  Future<T> logAction<T>(
    String label,
    List<Object?>? arguments,
    Future<T> Function() action,
  ) => action();
  @override
  Future<DatabaseExecutor> get executor => throw UnimplementedError();
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) =>
      throw UnimplementedError();
  @override
  Future<void> close() async {}
}

Table<_User> _usersTable() => Table<_User>(
  schema: 'CREATE TABLE users (id INTEGER, name TEXT, age INTEGER)',
  name: 'users',
  type: _User,
  fromJson: (m) => _User(m['id'] as int),
  columns: const ['id', 'name', 'age'],
);

void main() {
  late PhormCore<_User> core;

  setUp(() {
    final table = _usersTable();
    core = PhormCore<_User>(dbManager: _FakeDb([table]), table: table);
  });

  group('PhormQuery condition dispatch', () {
    const name = PhormColumn<String>('name');
    const age = PhormColumn<int>('age');
    const createdAt = PhormColumn<DateTime>('age'); // numeric col reused

    test('basic comparison operators compile into SQL', () {
      final sql =
          PhormQuery(core)
              .where(age.eq(1))
              .where(age.ne(2))
              .where(age.gt(3))
              .where(age.gte(4))
              .where(age.lt(5))
              .where(age.lte(6))
              .toSql();
      expect(sql, contains('users'));
      expect(sql, contains('age'));
    });

    test('pattern, null, and boolean operators do not throw', () {
      final q = PhormQuery(core)
          .where(name.like('%a%'))
          .where(name.notLike('%b%'))
          .where(name.ilike('%c%'))
          .where(name.notIlike('%d%'))
          .where(name.regexp('^x'))
          .where(name.startsWith('a'))
          .where(name.endsWith('z'))
          .where(name.isNull())
          .where(name.isNotNull())
          .where(age.isTrue())
          .where(age.isFalse());
      expect(q.toSql(), isNotEmpty);
    });

    test('list and range operators', () {
      final q = PhormQuery(core)
          .where(age.inList([1, 2]))
          .where(age.notInList([3, 4]))
          .where(age.between(1, 10))
          .where(age.notBetween(20, 30));
      expect(q.toSql(), contains('age'));
    });

    test('length and substr operators', () {
      final q = PhormQuery(core)
          .where(name.lengthEq(3))
          .where(name.lengthNe(4))
          .where(name.lengthGt(1))
          .where(name.lengthGte(2))
          .where(name.lengthLt(9))
          .where(name.lengthLte(8))
          .where(name.substrEq(1, 2, 'ab'))
          .where(name.substrLike(1, 2, 'a%'))
          .where(name.substrIlike(1, 2, 'a%'));
      expect(q.toSql(), isNotEmpty);
    });

    test('date/time operators', () {
      final d = DateTime(2024);
      final q = PhormQuery(core)
          .where(createdAt.dateOnlyEq(d))
          .where(createdAt.dateOnlyGt(d))
          .where(createdAt.dateOnlyLt(d))
          .where(createdAt.dateOnlyBetween(d, d))
          .where(createdAt.timeOnlyEq(d));
      expect(q.toSql(), isNotEmpty);
    });

    test('whereIf adds only when the flag is true', () {
      final included = PhormQuery(core).whereIf(true, () => age.gt(1)).toSql();
      final excluded = PhormQuery(core).whereIf(false, () => age.gt(1)).toSql();
      expect(included, contains('age'));
      // Excluded query has no WHERE filter on age.
      expect(excluded, isNot(contains('age >')));
    });

    test('whereNotNull adds only for non-null values', () {
      final q1 = PhormQuery(core).whereNotNull<int>(5, (v) => age.eq(v));
      final q2 = PhormQuery(core).whereNotNull<int>(null, (v) => age.eq(v));
      expect(q1.toSql(), contains('age'));
      expect(q2.toSql(), isNot(contains('age =')));
    });
  });

  group('PhormQuery chaining setters', () {
    test('all fluent setters return the same query instance', () {
      const age = PhormColumn<int>('age');
      final q = PhormQuery(core);
      expect(identical(q, q.limit(5)), isTrue);
      expect(identical(q, q.offset(2)), isTrue);
      expect(identical(q, q.orderBy(age)), isTrue);
      expect(identical(q, q.orderBy(age, descending: true)), isTrue);
      expect(identical(q, q.attributes(Attributes.include(['id']))), isTrue);
      expect(identical(q, q.withDeleted()), isTrue);
      expect(identical(q, q.include([Includable.table('posts')])), isTrue);
      expect(identical(q, q.includeOne(Includable.table('comments'))), isTrue);
    });

    test('orderBy and limit/offset are reflected in compiled SQL', () {
      const age = PhormColumn<int>('age');
      final sql =
          PhormQuery(
            core,
          ).orderBy(age, descending: true).limit(10).offset(5).toSql();
      expect(sql, contains('ORDER BY'));
      expect(sql, contains('age'));
    });
  });

  group('PhormDatabaseServiceExtension', () {
    test('service<T>() resolves a registered table', () {
      final db = _FakeDb([_usersTable()]);
      expect(db.service<_User>(), isA<PhormCore<_User>>());
    });

    test('service<T>() throws StateError for an unregistered type', () {
      final db = _FakeDb([]);
      expect(() => db.service<_User>(), throwsStateError);
    });
  });

  group('PhormQuery distinct / groupBy / having / select / noLimit', () {
    const age = PhormColumn<int>('age');
    const city = PhormColumn<String>('city');

    test('distinct() emits SELECT DISTINCT', () {
      final sql = PhormQuery(core).distinct().toSql();
      expect(sql, startsWith('SELECT DISTINCT '));
    });

    test('select() narrows the column list', () {
      final sql = PhormQuery(core).select([city, 'age']).toSql();
      expect(sql, contains('users.city'));
      expect(sql, contains('users.age'));
      expect(sql, isNot(contains('users.name')));
    });

    test('groupBy() emits GROUP BY with the given columns', () {
      final sql = PhormQuery(core).groupBy([city]).toSql();
      expect(sql, contains('GROUP BY city'));
    });

    test('having() compiles after GROUP BY', () {
      final sql = PhormQuery(core).groupBy([city]).having(age.gt(30)).toSql();
      expect(sql, contains('GROUP BY city HAVING age > ?'));
    });

    test('having without groupBy is ignored in SQL', () {
      final sql = PhormQuery(core).having(age.gt(30)).toSql();
      expect(sql, isNot(contains('HAVING')));
    });

    test('default limit is 20 and noLimit() removes it', () {
      expect(PhormQuery(core).toSql(), contains('LIMIT 20'));
      expect(PhormQuery(core).noLimit().toSql(), isNot(contains('LIMIT')));
    });

    test('explicit groupBy replaces automatic pk grouping', () {
      final sql =
          PhormQuery(core).where(city.eq('Sofia')).groupBy([city]).toSql();
      expect('GROUP BY'.allMatches(sql).length, 1);
      expect(sql, contains('GROUP BY city'));
    });
  });

  group('PhormQuery keyset pagination (after)', () {
    const age = PhormColumn<int>('age');
    const name = PhormColumn<String>('name');

    test('after() requires orderBy first', () {
      expect(() => PhormQuery(core).after(_User(1)), throwsStateError);
    });

    test('single ASC sort expands to gt with pk tiebreaker', () {
      final sql = PhormQuery(core).orderBy(age).after(_User(7)).toSql();
      // pk appended to ORDER BY as tiebreaker
      expect(sql, contains('ORDER BY age ASC, id ASC'));
      // (age > ?) OR (age = ? AND id > ?)
      expect(sql, contains('(age > ? OR (age = ? AND id > ?))'));
    });

    test('DESC sort flips the comparison', () {
      final sql =
          PhormQuery(
            core,
          ).orderBy(age, descending: true).after(_User(7)).toSql();
      expect(sql, contains('ORDER BY age DESC, id ASC'));
      expect(sql, contains('(age < ? OR (age = ? AND id > ?))'));
    });

    test('mixed multi-column sort expands per direction', () {
      final sql =
          PhormQuery(core)
              .orderBy(name)
              .orderBy(age, descending: true)
              .after(_User(7, age: 3, name: 'x'))
              .toSql();
      expect(
        sql,
        contains(
          '(name > ? OR (name = ? AND age < ?) '
          'OR (name = ? AND age = ? AND id > ?))',
        ),
      );
    });

    test('cursor values come from the model in sort order', () async {
      final q = PhormQuery(core).orderBy(age).after(_User(7));
      // _User.toJson has id and (test model) age/name values
      expect(q.toSql(), contains('age > ?'));
    });

    test('null cursor value throws ArgumentError', () {
      expect(
        () => PhormQuery(core).orderBy(name).after(_User(1)),
        throwsArgumentError,
      );
    });
  });
}
