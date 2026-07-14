import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

class _User extends Model {
  _User(this.id);
  final int id;
  @override
  Map<String, dynamic> toJson() => {'id': id};
}

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
  Future<DatabaseExecutor> get executor =>
      throw UnimplementedError('not needed for SQL building');

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) =>
      throw UnimplementedError('not needed for SQL building');

  @override
  Future<void> close() async {}
}

void main() {
  const name = PhormColumn<String>('name');
  const age = PhormColumn<int>('age');
  const city = PhormColumn<String>('city');

  late PhormCore<_User> core;

  setUp(() {
    final table = Table<_User>(
      schema:
          'CREATE TABLE users (id INTEGER, name TEXT, age INTEGER, city TEXT)',
      name: 'users',
      type: _User,
      fromJson: (m) => _User(m['id'] as int),
      columns: const ['id', 'name', 'age', 'city'],
    );
    core = PhormCore<_User>(dbManager: _FakeDb([table]), table: table);
  });

  group('PhormCondition & / | composition', () {
    test('& produces an AND group', () {
      final group = age.gt(18) & name.like('%a%');
      expect(group.isOr, isFalse);
      expect(group.conditions, hasLength(2));
    });

    test('consecutive & flattens into one group', () {
      final group = age.gt(18) & name.like('%a%') & city.eq('Sofia');
      expect(group.conditions, hasLength(3));
    });

    test('consecutive | flattens into one group', () {
      final group = city.eq('Sofia') | city.eq('Plovdiv') | city.eq('Varna');
      expect(group.isOr, isTrue);
      expect(group.conditions, hasLength(3));
    });

    test('OR group compiles into parenthesized SQL', () {
      final sql =
          PhormQuery(core).where(city.eq('Sofia') | city.eq('Plovdiv')).toSql();
      expect(sql, contains('(city = ? OR city = ?)'));
    });

    test('& binds tighter than | and mixed groups nest', () {
      final sql =
          PhormQuery(
            core,
          ).where(age.gt(18) & (city.eq('Sofia') | city.eq('Plovdiv'))).toSql();
      expect(sql, contains('(age > ? AND (city = ? OR city = ?))'));
    });

    test('composition works alongside plain chained where()', () {
      final sql =
          PhormQuery(
            core,
          ).where(name.isNotNull()).where(age.gte(21) | age.isNull()).toSql();
      expect(sql, contains('name IS NOT NULL'));
      expect(sql, contains('(age >= ? OR age IS NULL)'));
    });

    test('typed operators inside groups keep their SQL shape', () {
      final sql =
          PhormQuery(
            core,
          ).where(name.startsWith('Jo') & age.between(18, 65)).toSql();
      expect(sql, contains('name LIKE ?'));
      expect(sql, contains('age BETWEEN ? AND ?'));
    });
  });
}
