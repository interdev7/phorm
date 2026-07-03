// Microbenchmark: inline vs. isolate row parsing in PhormCore.readAll().
//
// The core spawns an `Isolate.run` to map rows into models when the result set
// exceeds `isolateThreshold`. Spawning an isolate + copying the rows across the
// isolate boundary has a fixed cost, so below some row count it is cheaper to
// parse inline on the current thread. This benchmark measures the real
// `readAll()` path at both settings across a range of row counts to locate the
// break-even point and justify the default threshold.
//
// Run with:  dart run benchmark/parse_benchmark.dart
//            (phorm/lib imports no Flutter, so plain `dart run` works.)

// A benchmark harness reports its results to stdout by design.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:phorm/phorm.dart';

// ---------------------------------------------------------------------------
// A small but non-trivial model — several typed fields so fromJson does real
// work per row (int/String/bool coercion).
// ---------------------------------------------------------------------------
class _User extends Model {
  _User(this.id, this.name, this.age, this.active, this.createdAt);
  final int id;
  final String name;
  final int age;
  final bool active;
  final String createdAt;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'active': active ? 1 : 0,
    'created_at': createdAt,
  };
}

_User _userFromJson(Map<String, dynamic> m) => _User(
  m['id'] as int,
  m['name'] as String,
  m['age'] as int,
  (m['active'] as int) == 1,
  m['created_at'] as String,
);

Table<_User> _usersTable() => Table<_User>(
  schema:
      'CREATE TABLE users (id INTEGER, name TEXT, age INTEGER, '
      'active INTEGER, created_at TEXT)',
  name: 'users',
  type: _User,
  fromJson: _userFromJson,
  timestamps: false,
  columns: const ['id', 'name', 'age', 'active', 'created_at'],
);

// ---------------------------------------------------------------------------
// Fake executor that returns a fixed set of pre-built rows for any query.
// ---------------------------------------------------------------------------
class _FixedExecutor implements DatabaseExecutor {
  _FixedExecutor(this.rows);
  final List<Map<String, Object?>> rows;

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async => rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDb implements PhormDatabase {
  _FakeDb(this._tables, this._executor, this._isolateThreshold);
  final List<Table> _tables;
  final DatabaseExecutor _executor;
  final int _isolateThreshold;

  @override
  SqlDialect get dialect => const NoEscapeDialect();
  @override
  List<Table> get tables => _tables;
  @override
  PhormLogger? get logger => null;
  @override
  int get isolateThreshold => _isolateThreshold;
  @override
  Stream<String> get changeStream => const Stream.empty();
  @override
  Future<T> logAction<T>(
    String label,
    List<Object?>? args,
    Future<T> Function() action,
  ) => action();
  @override
  Future<DatabaseExecutor> get executor async => _executor;
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) a) =>
      a(_executor);
  @override
  Future<void> close() async {}
}

List<Map<String, Object?>> _makeRows(int n) => List.generate(
  n,
  (i) => <String, Object?>{
    'id': i,
    'name': 'user_$i',
    'age': 20 + (i % 50),
    'active': i.isEven ? 1 : 0,
    'created_at': '2024-01-01T00:00:00.000',
  },
);

Future<double> _timeReadAll(
  List<Map<String, Object?>> rows,
  int threshold, {
  required int iterations,
}) async {
  final table = _usersTable();
  final core = PhormCore<_User>(
    dbManager: _FakeDb([table], _FixedExecutor(rows), threshold),
    table: table,
  );
  // Warm-up (JIT + first isolate spawn).
  await core.readAll(limit: rows.length);

  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    final res = await core.readAll(limit: rows.length);
    if (res.data.length != rows.length) {
      throw StateError('parsed ${res.data.length} of ${rows.length}');
    }
  }
  sw.stop();
  return sw.elapsedMicroseconds / iterations / 1000.0; // ms per readAll
}

Future<void> main() async {
  const counts = [100, 200, 500, 1000, 2000, 5000, 20000, 50000];
  const veryHigh = 1 << 30; // force inline
  const zero = 0; // force isolate (rows.length > 0)

  print('rows | inline (ms) | isolate (ms) | winner');
  print('-----+-------------+--------------+--------');
  for (final n in counts) {
    final rows = _makeRows(n);
    // Fewer iterations for big sets to keep total runtime sane.
    final iters = n >= 5000 ? 20 : (n >= 500 ? 50 : 200);
    final inline = await _timeReadAll(rows, veryHigh, iterations: iters);
    final isolate = await _timeReadAll(rows, zero, iterations: iters);
    final winner = inline <= isolate ? 'inline' : 'isolate';
    print(
      '${n.toString().padLeft(5)}'
      ' | ${inline.toStringAsFixed(3).padLeft(11)}'
      ' | ${isolate.toStringAsFixed(3).padLeft(12)}'
      ' | $winner',
    );
  }
}
