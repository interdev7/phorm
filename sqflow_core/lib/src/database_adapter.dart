import 'dart:async';

import 'database_isolate.dart';
import 'sql_function.dart';

/// Adapter that provides sqlite3-based API over isolate
class Database implements DatabaseExecutor {
  final DatabaseIsolate _isolate;
  final String path;

  Database._(this._isolate, this.path);

  /// Stream of table names that have been modified
  Stream<String> get changeStream => _isolate.changeStream;

  static Future<Database> open(
    String path, {
    List<SqlFunction>? customFunctions,
  }) async {
    // createDatabaseIsolate() is provided by the conditional import:
    //   - native: NativeDatabaseIsolate (dart:isolate + sqlite3)
    //   - web:    WebDatabaseIsolate    (WasmSqlite3)
    final isolate = createDatabaseIsolate();
    if (customFunctions != null && customFunctions.isNotEmpty) {
      isolate.registerFunctions(customFunctions);
    }
    await isolate.start();
    await isolate.open(path);
    return Database._(isolate, path);
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _isolate.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?>? arguments]) =>
      _isolate.query(sql, arguments);

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
  }) {
    final sql = StringBuffer('SELECT ');
    if (distinct ?? false) sql.write('DISTINCT ');
    sql
      ..write(columns?.join(', ') ?? '*')
      ..write(' FROM $table');
    if (where != null) sql.write(' WHERE $where');
    if (groupBy != null) sql.write(' GROUP BY $groupBy');
    if (having != null) sql.write(' HAVING $having');
    if (orderBy != null) sql.write(' ORDER BY $orderBy');
    if (limit != null) sql.write(' LIMIT $limit');
    if (offset != null) sql.write(' OFFSET $offset');
    return _isolate.query(sql.toString(), whereArgs);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final columns = values.keys.toList();
    final placeholders = List.filled(columns.length, '?').join(', ');
    final conflictClause = conflictAlgorithm != null
        ? ' OR ${_conflictToString(conflictAlgorithm)}'
        : '';
    final sql =
        'INSERT$conflictClause INTO $table (${columns.join(', ')}) VALUES ($placeholders)';
    await _isolate.execute(sql, columns.map((c) => values[c]).toList());
    return await _isolate
        .query('SELECT last_insert_rowid() as id')
        .then((r) => r.first['id'] as int);
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      _isolate.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _isolate.delete(table, where: where, whereArgs: whereArgs);

  @override
  Batch batch() => Batch._(this);

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final txn = Transaction._(this);
    await execute('BEGIN');
    try {
      final result = await action(txn);
      await execute('COMMIT');
      return result;
    } catch (e) {
      await execute('ROLLBACK');
      rethrow;
    }
  }

  Future<int> getVersion() => _isolate.getVersion();

  Future<void> setVersion(int version) => _isolate.setVersion(version);

  Future<void> close() => _isolate.stop();

  String _conflictToString(ConflictAlgorithm algorithm) {
    switch (algorithm) {
      case ConflictAlgorithm.rollback:
        return 'ROLLBACK';
      case ConflictAlgorithm.abort:
        return 'ABORT';
      case ConflictAlgorithm.fail:
        return 'FAIL';
      case ConflictAlgorithm.ignore:
        return 'IGNORE';
      case ConflictAlgorithm.replace:
        return 'REPLACE';
    }
  }
}

/// Transaction wrapper
class Transaction implements DatabaseExecutor {
  final Database _db;

  Transaction._(this._db);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _db.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?>? arguments]) =>
      _db.rawQuery(sql, arguments);

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
  }) =>
      _db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      _db.insert(table, values,
          nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) =>
      _db.update(table, values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _db.delete(table, where: where, whereArgs: whereArgs);

  @override
  Batch batch() => _db.batch();
}

/// Batch wrapper
class Batch {
  final Database _db;
  final _operations = <_BatchOp>[];

  Batch._(this._db);

  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add(_BatchOp.insert(table, values, conflictAlgorithm));
  }

  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add(
        _BatchOp.update(table, values, where, whereArgs, conflictAlgorithm));
  }

  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _operations.add(_BatchOp.delete(table, where, whereArgs));
  }

  void execute(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  void rawInsert(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  void rawUpdate(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  void rawDelete(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  Future<List<Object?>> commit({bool? noResult, bool? continueOnError}) async {
    await _db.execute('BEGIN');
    try {
      final results = <Object?>[];
      for (final op in _operations) {
        try {
          final result = await op.execute(_db);
          results.add(result);
        } catch (e) {
          if (!(continueOnError ?? false)) {
            await _db.execute('ROLLBACK');
            rethrow;
          }
          results.add(e);
        }
      }
      await _db.execute('COMMIT');
      return (noResult ?? false) ? [] : results;
    } catch (e) {
      await _db.execute('ROLLBACK');
      rethrow;
    }
  }
}

class _BatchOp {
  final String type;
  final String? table;
  final Map<String, Object?>? values;
  final String? where;
  final List<Object?>? whereArgs;
  final ConflictAlgorithm? conflictAlgorithm;
  final String? sql;
  final List<Object?>? arguments;

  _BatchOp.insert(this.table, this.values, this.conflictAlgorithm)
      : type = 'insert',
        where = null,
        whereArgs = null,
        sql = null,
        arguments = null;

  _BatchOp.update(this.table, this.values, this.where, this.whereArgs,
      this.conflictAlgorithm)
      : type = 'update',
        sql = null,
        arguments = null;

  _BatchOp.delete(this.table, this.where, this.whereArgs)
      : type = 'delete',
        values = null,
        conflictAlgorithm = null,
        sql = null,
        arguments = null;

  _BatchOp.execute(this.sql, this.arguments)
      : type = 'execute',
        table = null,
        values = null,
        where = null,
        whereArgs = null,
        conflictAlgorithm = null;

  Future<Object?> execute(Database db) async {
    switch (type) {
      case 'insert':
        return await db.insert(table!, values!,
            conflictAlgorithm: conflictAlgorithm);
      case 'update':
        return await db.update(table!, values!,
            where: where,
            whereArgs: whereArgs,
            conflictAlgorithm: conflictAlgorithm);
      case 'delete':
        return await db.delete(table!, where: where, whereArgs: whereArgs);
      case 'execute':
        await db.execute(sql!, arguments);
        return null;
      default:
        throw StateError('Unknown batch operation type: $type');
    }
  }
}

/// Database executor interface
abstract interface class DatabaseExecutor {
  Future<void> execute(String sql, [List<Object?>? arguments]);
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]);
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
  });
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  });
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  });
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});
  Batch batch();
}

/// Conflict algorithm enum
enum ConflictAlgorithm {
  rollback,
  abort,
  fail,
  ignore,
  replace,
}
