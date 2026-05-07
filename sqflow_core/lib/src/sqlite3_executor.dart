import 'dart:async';

import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Implementation of [SqflowDatabaseExecutor] using the pure Dart [sqlite3] package.
class Sqlite3ExecutorWrapper implements SqflowDatabaseExecutor {
  final sqlite.Database _db;

  Sqlite3ExecutorWrapper(this._db);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    _db.execute(sql, arguments ?? []);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    final resultSet = _db.select(sql, arguments ?? []);
    return resultSet.map((row) => Map<String, Object?>.from(row)).toList();
  }

  @override
  SqflowBatch batch() => Sqlite3BatchWrapper(_db);

  @override
  Future<R> transaction<R>(
      Future<R> Function(SqflowDatabaseExecutor txn) action) async {
    _db.execute('BEGIN TRANSACTION');
    try {
      final result = await action(this);
      _db.execute('COMMIT');
      return result;
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

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
  }) async {
    final select = columns?.join(', ') ?? '*';
    final distinctClause = distinct == true ? 'DISTINCT ' : '';
    var sql = 'SELECT $distinctClause$select FROM $table';

    if (where != null) {
      sql += ' WHERE $where';
    }
    if (groupBy != null) {
      sql += ' GROUP BY $groupBy';
    }
    if (having != null) {
      sql += ' HAVING $having';
    }
    if (orderBy != null) {
      sql += ' ORDER BY $orderBy';
    }
    if (limit != null) {
      sql += ' LIMIT $limit';
    }
    if (offset != null) {
      sql += ' OFFSET $offset';
    }

    return rawQuery(sql, whereArgs);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    String? conflictAlgorithm,
  }) async {
    final keys = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final conflict = conflictAlgorithm != null ? 'OR $conflictAlgorithm ' : '';

    final sql = 'INSERT ${conflict}INTO $table ($keys) VALUES ($placeholders)';
    _db.execute(sql, values.values.toList());

    return _db.lastInsertRowId;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final setClause = values.keys.map((k) => '$k = ?').join(', ');
    var sql = 'UPDATE $table SET $setClause';

    if (where != null) {
      sql += ' WHERE $where';
    }

    final args = [...values.values, ...(whereArgs ?? [])];
    _db.execute(sql, args);

    return _db.getUpdatedRows();
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    var sql = 'DELETE FROM $table';

    if (where != null) {
      sql += ' WHERE $where';
    }

    _db.execute(sql, whereArgs ?? []);
    return _db.getUpdatedRows();
  }
}

class Sqlite3BatchWrapper implements SqflowBatch {
  final sqlite.Database _db;
  final List<Future<void> Function()> _operations = [];

  Sqlite3BatchWrapper(this._db);

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _operations.add(() async {
      var sql = 'DELETE FROM $table';
      if (where != null) sql += ' WHERE $where';
      _db.execute(sql, whereArgs ?? []);
    });
  }

  @override
  void execute(String sql, [List<Object?>? arguments]) {
    _operations.add(() async => _db.execute(sql, arguments ?? []));
  }

  @override
  void insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, String? conflictAlgorithm}) {
    _operations.add(() async {
      final keys = values.keys.join(', ');
      final placeholders = List.filled(values.length, '?').join(', ');
      final conflict =
          conflictAlgorithm != null ? 'OR $conflictAlgorithm ' : '';
      final sql =
          'INSERT ${conflict}INTO $table ($keys) VALUES ($placeholders)';
      _db.execute(sql, values.values.toList());
    });
  }

  @override
  void update(String table, Map<String, Object?> values,
      {String? where, List<Object?>? whereArgs}) {
    _operations.add(() async {
      final setClause = values.keys.map((k) => '$k = ?').join(', ');
      var sql = 'UPDATE $table SET $setClause';
      if (where != null) sql += ' WHERE $where';
      final args = [...values.values, ...(whereArgs ?? [])];
      _db.execute(sql, args);
    });
  }

  @override
  Future<List<Object?>> commit(
      {bool? exclusive, bool? noResult, bool? continueOnError}) async {
    if (_operations.isEmpty) return [];

    _db.execute('BEGIN TRANSACTION');
    final results = <Object?>[];
    try {
      for (final op in _operations) {
        await op();
        results.add(null); // Simple result mapping for now
      }
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      if (continueOnError != true) rethrow;
    }
    return results;
  }
}
