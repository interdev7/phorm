import 'dart:async';

import 'package:phorm_annotations/phorm_annotations.dart';

/// Database engine conflict resolution algorithms.
enum ConflictAlgorithm {
  /// Rolls back the whole transaction on conflict.
  rollback,

  /// Aborts the current statement, keeping prior changes.
  abort,

  /// Fails the statement but keeps changes made by it so far.
  fail,

  /// Skips the conflicting row and continues.
  ignore,

  /// Replaces the existing row with the new one.
  replace,
}

/// Abstract interface representing a batch of write operations.
abstract interface class Batch {
  /// Queues an INSERT into [table].
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  });

  /// Queues an UPDATE of [table].
  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  });

  /// Queues a DELETE from [table].
  void delete(String table, {String? where, List<Object?>? whereArgs});

  /// Queues a raw SQL statement.
  void execute(String sql, [List<Object?>? arguments]);

  /// Queues a raw INSERT statement.
  void rawInsert(String sql, [List<Object?>? arguments]);

  /// Queues a raw UPDATE statement.
  void rawUpdate(String sql, [List<Object?>? arguments]);

  /// Queues a raw DELETE statement.
  void rawDelete(String sql, [List<Object?>? arguments]);

  /// Executes all queued operations, returning their results in order.
  Future<List<Object?>> commit({bool? noResult, bool? continueOnError});
}

/// Abstract interface representing a database executor (either database connection or transaction).
abstract interface class DatabaseExecutor {
  /// Executes a raw SQL statement without returning rows.
  Future<void> execute(String sql, [List<Object?>? arguments]);

  /// Runs a raw SELECT and returns the resulting rows.
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]);

  /// Runs a structured SELECT against [table].
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

  /// Inserts [values] into [table]; returns the new row id.
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  });

  /// Updates [table] rows matching [where]; returns the affected count.
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  });

  /// Deletes [table] rows matching [where]; returns the affected count.
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  /// Starts a new batch of write operations.
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
    String label,
    List<Object?>? arguments,
    Future<T> Function() action,
  );

  /// Resolves the underlying database executor.
  Future<DatabaseExecutor> get executor;

  /// Starts a transaction.
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action);

  /// Closes the database connection and releases resources.
  Future<void> close();
}
