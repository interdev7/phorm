import 'dart:async';
import 'package:phorm/phorm.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'database_isolate.dart';
import 'sql_function.dart';

/// SQLite database implementation of the DatabaseExecutor interface.
class Database implements DatabaseExecutor {
  final DatabaseIsolate _isolate;
  final String path;

  Database._(this._isolate, this.path);

  /// Stream of table names that have been modified
  Stream<String> get changeStream => _isolate.changeStream;

  static Future<Database> open(
    String path, {
    List<SqlFunction>? customFunctions,
    String? password,
  }) async {
    final isolate = createDatabaseIsolate();
    if (customFunctions != null && customFunctions.isNotEmpty) {
      isolate.registerFunctions(customFunctions);
    }
    await isolate.start();
    await isolate.open(path, password: password);
    return Database._(isolate, path);
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _wrapException(
        () => _isolate.execute(sql, arguments),
        table: _parseTableFromSql(sql),
        sql: sql,
      );

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) => _wrapException(
    () => _isolate.query(sql, arguments),
    table: _parseTableFromSql(sql),
    sql: sql,
  );

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
    return _wrapException(
      () => _isolate.query(sql.toString(), whereArgs),
      table: table,
      sql: sql.toString(),
    );
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
    return _wrapException(
      () async {
        await _isolate.execute(sql, columns.map((c) => values[c]).toList());
        return _isolate
            .query('SELECT last_insert_rowid() as id')
            .then((r) => r.first['id']! as int);
      },
      table: table,
      values: values,
      sql: sql,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) => _wrapException(
    () => _isolate.update(table, values, where: where, whereArgs: whereArgs),
    table: table,
    values: values,
  );

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _wrapException(
        () => _isolate.delete(table, where: where, whereArgs: whereArgs),
        table: table,
      );

  @override
  Batch batch() => SqliteBatch._(this);

  /// Current transaction nesting depth: 0 = no active transaction.
  int _transactionDepth = 0;

  /// Runs [action] inside a transaction.
  ///
  /// Nested calls are supported via SQLite savepoints: the outermost call
  /// issues `BEGIN`/`COMMIT`, inner calls create a `SAVEPOINT` that is
  /// released on success or rolled back on failure — so a failed inner
  /// transaction undoes only its own writes, while the outer transaction
  /// decides independently whether to commit.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final txn = Transaction._(this);
    final depth = _transactionDepth;
    final savepoint = 'phorm_sp_$depth';

    await execute(depth == 0 ? 'BEGIN' : 'SAVEPOINT $savepoint');
    _transactionDepth++;
    try {
      final result = await action(txn);
      await execute(depth == 0 ? 'COMMIT' : 'RELEASE SAVEPOINT $savepoint');
      return result;
    } catch (e) {
      if (depth == 0) {
        await execute('ROLLBACK');
      } else {
        await execute('ROLLBACK TO SAVEPOINT $savepoint');
        await execute('RELEASE SAVEPOINT $savepoint');
      }
      rethrow;
    } finally {
      _transactionDepth--;
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

/// SQLite Transaction wrapper implementing DatabaseExecutor from `phorm`.
class Transaction implements DatabaseExecutor {
  final Database _db;

  Transaction._(this._db);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _db.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) => _db.rawQuery(sql, arguments);

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
  }) => _db.query(
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
  }) => _db.insert(
    table,
    values,
    nullColumnHack: nullColumnHack,
    conflictAlgorithm: conflictAlgorithm,
  );

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) => _db.update(
    table,
    values,
    where: where,
    whereArgs: whereArgs,
    conflictAlgorithm: conflictAlgorithm,
  );

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _db.delete(table, where: where, whereArgs: whereArgs);

  @override
  Batch batch() => _db.batch();
}

/// SQLite Batch implementation of the Batch interface from `phorm`.
class SqliteBatch implements Batch {
  final Database _db;
  final _operations = <_BatchOp>[];

  SqliteBatch._(this._db);

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add(_BatchOp.insert(table, values, conflictAlgorithm));
  }

  @override
  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add(
      _BatchOp.update(table, values, where, whereArgs, conflictAlgorithm),
    );
  }

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _operations.add(_BatchOp.delete(table, where, whereArgs));
  }

  @override
  void execute(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {
    _operations.add(_BatchOp.execute(sql, arguments));
  }

  @override
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

  _BatchOp.update(
    this.table,
    this.values,
    this.where,
    this.whereArgs,
    this.conflictAlgorithm,
  ) : type = 'update',
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
        return db.insert(
          table!,
          values!,
          conflictAlgorithm: conflictAlgorithm,
        );
      case 'update':
        return db.update(
          table!,
          values!,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm,
        );
      case 'delete':
        return db.delete(table!, where: where, whereArgs: whereArgs);
      case 'execute':
        await db.execute(sql!, arguments);
        return null;
      // coverage:ignore-start
      default:
        throw StateError('Unknown batch operation type: $type');
      // coverage:ignore-end
    }
  }
}

Future<T> _wrapException<T>(
  Future<T> Function() action, {
  required String table,
  Map<String, Object?>? values,
  String? sql,
}) async {
  try {
    return await action();
  } on SqliteException catch (e) {
    final message = e.message;
    if (message.contains('CHECK constraint failed')) {
      final parts = message.split('CHECK constraint failed:');
      String? constraint;
      if (parts.length > 1) {
        constraint = parts[1].trim();
      }

      String? column;
      if (constraint != null && values != null) {
        final sortedKeys = values.keys.toList()
          ..sort((a, b) => b.length.compareTo(a.length));
        for (final key in sortedKeys) {
          if (constraint.contains(key)) {
            column = key;
            break;
          }
        }
      }

      if (column == null && constraint != null) {
        var clean = constraint;
        if (clean.endsWith('_check')) {
          clean = clean.substring(0, clean.length - 6);
        }
        if (clean.endsWith('_length')) {
          clean = clean.substring(0, clean.length - 7);
        }
        if (clean.startsWith('${table}_')) {
          clean = clean.substring(table.length + 1);
        }
        column = clean;
      }

      throw PhormCHECKValidatorException(
        table: table,
        column: column ?? '',
        message: message,
        constraint: constraint,
      );
    }
    rethrow;
  }
}

String _parseTableFromSql(String sql) {
  final insertMatch = RegExp(
    r'INSERT\s+(?:OR\s+\w+\s+)?INTO\s+(\w+)',
    caseSensitive: false,
  ).firstMatch(sql);
  if (insertMatch != null) return insertMatch.group(1)!;

  final updateMatch = RegExp(
    r'UPDATE\s+(\w+)',
    caseSensitive: false,
  ).firstMatch(sql);
  if (updateMatch != null) return updateMatch.group(1)!;

  final deleteMatch = RegExp(
    r'DELETE\s+FROM\s+(\w+)',
    caseSensitive: false,
  ).firstMatch(sql);
  if (deleteMatch != null) return deleteMatch.group(1)!;

  return '';
}
