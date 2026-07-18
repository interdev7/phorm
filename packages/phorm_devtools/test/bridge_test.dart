import 'dart:async';

import 'package:phorm/phorm.dart';
import 'package:phorm_devtools/src/bridge.dart';
import 'package:test/test.dart';

class _FakeExecutor implements DatabaseExecutor {
  final List<(String, List<Object?>?)> queries = [];
  List<Map<String, Object?>> nextRows = [];

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    queries.add((sql, arguments));
    if (sql.startsWith('SELECT COUNT')) {
      return [
        {'c': nextRows.length},
      ];
    }
    return nextRows;
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    queries.add((sql, arguments));
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    queries.add(('INSERT INTO $table', values.values.toList()));
    return 1;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    queries.add(('UPDATE $table SET $values WHERE $where', whereArgs));
    return 1;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    queries.add(('DELETE FROM $table WHERE $where', whereArgs));
    return 1;
  }

  @override
  Batch batch() => throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async =>
      nextRows;
}

class _FakeModel extends Model {
  @override
  Map<String, dynamic> toJson() => const {};
}

class _FakeDb implements PhormDatabase {
  final _FakeExecutor fakeExecutor = _FakeExecutor();

  @override
  final List<Table> tables = [
    Table<_FakeModel>(
      schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, deleted_at TEXT)',
      name: 'users',
      fromJson: (_) => _FakeModel(),
      type: _FakeModel,
      paranoid: true,
      columns: const ['id', 'name', 'deleted_at'],
    ),
  ];

  @override
  Future<DatabaseExecutor> get executor async => fakeExecutor;

  @override
  Stream<String> get changeStream => const Stream.empty();

  @override
  SqlDialect get dialect => throw UnimplementedError();

  @override
  int get isolateThreshold => 0;

  @override
  Future<T> logAction<T>(
    String label,
    List<Object?>? arguments,
    Future<T> Function() action,
  ) =>
      action();

  @override
  PhormLogger? get logger => null;

  @override
  Future<T> transaction<T>(
    Future<T> Function(DatabaseExecutor txn) action,
  ) =>
      action(fakeExecutor);

  @override
  Future<void> close() async {}
}

void main() {
  final db = _FakeDb();
  late PhormDevtoolsBridge bridge;

  setUpAll(() {
    PhormDevtoolsBridge.attach(db, label: 'test.db');
    bridge = PhormDevtoolsBridge.instance!;
  });

  test('attach installs itself as PhormInstrumentation', () {
    expect(PhormInstrumentation.instance, same(bridge));
  });

  test('getInfo reports protocol version and databases', () async {
    final info = await bridge.handleGetInfo({});
    expect(info['protocolVersion'], PhormDevtoolsBridge.protocolVersion);
    expect(info['databases'], contains('main'));
  });

  test('getTables serializes table metadata', () async {
    final result = await bridge.handleGetTables({'dbId': 'main'});
    final tables = result['tables'] as List;
    final users = (tables.single as Map).cast<String, Object?>();
    expect(users['name'], 'users');
    expect(users['paranoid'], true);
    expect(users['columns'], ['id', 'name', 'deleted_at']);
  });

  test('queryData filters soft-deleted rows and paginates', () async {
    db.fakeExecutor.queries.clear();
    db.fakeExecutor.nextRows = [
      {'id': 'u1', 'name': 'John', 'deleted_at': null},
    ];
    final result = await bridge.handleQueryData({
      'dbId': 'main',
      'table': 'users',
      'limit': '10',
      'offset': '5',
      'orderBy': 'name',
      'orderDir': 'desc',
    });
    expect(result['totalCount'], 1);
    expect((result['rows'] as List).single, isA<Map>());
    final dataSql = db.fakeExecutor.queries.last;
    expect(dataSql.$1, contains('deleted_at IS NULL'));
    expect(dataSql.$1, contains('ORDER BY "name" DESC'));
    expect(dataSql.$2, containsAllInOrder([10, 5]));
  });

  test('queryData rejects unknown orderBy column (no SQL injection)', () async {
    final result = await bridge.handleQueryData({
      'dbId': 'main',
      'table': 'users',
      'orderBy': 'name; DROP TABLE users',
    });
    expect((result['error'] as Map)['code'], 'BAD_REQUEST');
  });

  test('mutateData delete on paranoid table is a soft delete', () async {
    db.fakeExecutor.queries.clear();
    final result = await bridge.handleMutateData({
      'dbId': 'main',
      'table': 'users',
      'action': 'delete',
      'primaryKey': 'u1',
    });
    expect(result['success'], true);
    expect(db.fakeExecutor.queries.single.$1, startsWith('UPDATE users'));
    expect(db.fakeExecutor.queries.single.$1, contains('deleted_at'));
  });

  test('mutateData unknown action returns error', () async {
    final result = await bridge.handleMutateData({
      'dbId': 'main',
      'table': 'users',
      'action': 'truncate',
    });
    expect((result['error'] as Map)['code'], 'BAD_REQUEST');
  });

  test('query events land in ring buffer and details are retrievable',
      () async {
    bridge.queryExecuted(
      db,
      QueryEvent(
        sql: 'SELECT * FROM users',
        duration: const Duration(milliseconds: 2),
      ),
    );
    final details = await bridge.handleGetQueryDetails({'queryId': '0'});
    expect(details['sql'], 'SELECT * FROM users');
    expect(details['dbId'], 'main');
  });

  test('stream lifecycle is tracked with emit counts', () async {
    bridge.streamCreated(
      const StreamWatchEvent(
        id: 7,
        kind: 'watchAll',
        table: 'users',
        dependencies: ['users'],
      ),
    );
    bridge.streamEmitted(7);
    bridge.streamEmitted(7);

    var result = await bridge.handleGetActiveStreams({});
    final stream =
        ((result['streams'] as List).single as Map).cast<String, Object?>();
    expect(stream['id'], 's_7');
    expect(stream['emitCount'], 2);

    bridge.streamDestroyed(7);
    result = await bridge.handleGetActiveStreams({});
    expect(result['streams'], isEmpty);
  });

  test('unknown dbId returns DB_NOT_FOUND', () async {
    final result = await bridge.handleGetTables({'dbId': 'nope'});
    expect((result['error'] as Map)['code'], 'DB_NOT_FOUND');
  });
}
