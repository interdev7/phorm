import 'dart:async';

import 'package:phorm_annotations/phorm_annotations.dart';

import 'dialect.dart';

/// Database engine conflict resolution algorithms.
enum ConflictAlgorithm {
  rollback,
  abort,
  fail,
  ignore,
  replace,
}

/// Abstract interface representing a batch of write operations.
abstract interface class Batch {
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  });

  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  });

  void delete(String table, {String? where, List<Object?>? whereArgs});

  void execute(String sql, [List<Object?>? arguments]);
  void rawInsert(String sql, [List<Object?>? arguments]);
  void rawUpdate(String sql, [List<Object?>? arguments]);
  void rawDelete(String sql, [List<Object?>? arguments]);

  Future<List<Object?>> commit({bool? noResult, bool? continueOnError});
}

/// Abstract interface representing a database executor (either database connection or transaction).
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

/// Abstract connection manager interface that is database-engine agnostic.
abstract interface class PhormDatabase {
  /// The active SQL dialect for this database.
  SqlDialect get dialect;

  /// The list of all registered table configurations.
  List<Table> get tables;

  /// The stream of modified table names for reactivity.
  Stream<String> get changeStream;

  /// Optional logger for database events.
  PhormLogger? get logger;

  /// Performance threshold for using isolate/async execution.
  int get isolateThreshold;

  /// Executes an operation inside a trace/log block.
  Future<T> logAction<T>(
      String label, List<Object?>? arguments, Future<T> Function() action);

  /// Resolves the underlying database executor.
  Future<DatabaseExecutor> get executor;

  /// Starts a transaction.
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action);

  /// Closes the database connection and releases resources.
  Future<void> close();
}
