// Common types and utilities shared between IO and Web implementations.
// This file must NOT import dart:isolate or sqlite3 directly.
import 'dart:async';

import 'sql_function.dart';

/// Commands that can be sent to the database backend
sealed class DatabaseCommand {
  const DatabaseCommand();
}

class OpenCommand extends DatabaseCommand {
  final String path;
  final String? password;
  const OpenCommand(this.path, {this.password});
}

class CloseCommand extends DatabaseCommand {
  const CloseCommand();
}

class ExecuteCommand extends DatabaseCommand {
  final String sql;
  final List<Object?>? args;
  const ExecuteCommand(this.sql, this.args);
}

class QueryCommand extends DatabaseCommand {
  final String sql;
  final List<Object?>? args;
  const QueryCommand(this.sql, this.args);
}

class InsertCommand extends DatabaseCommand {
  final String table;
  final Map<String, Object?> values;
  const InsertCommand(this.table, this.values);
}

class UpdateCommand extends DatabaseCommand {
  final String table;
  final Map<String, Object?> values;
  final String? where;
  final List<Object?>? whereArgs;
  const UpdateCommand(this.table, this.values, this.where, this.whereArgs);
}

class DeleteCommand extends DatabaseCommand {
  final String table;
  final String? where;
  final List<Object?>? whereArgs;
  const DeleteCommand(this.table, this.where, this.whereArgs);
}

class BatchCommand extends DatabaseCommand {
  final List<BatchOperation> operations;
  const BatchCommand(this.operations);
}

class TransactionCommand extends DatabaseCommand {
  final List<DatabaseCommand> commands;
  const TransactionCommand(this.commands);
}

class GetVersionCommand extends DatabaseCommand {
  const GetVersionCommand();
}

class SetVersionCommand extends DatabaseCommand {
  final int version;
  const SetVersionCommand(this.version);
}

/// Batch operation types
sealed class BatchOperation {
  const BatchOperation();
}

class BatchInsert extends BatchOperation {
  final String table;
  final Map<String, Object?> values;
  final bool replace;
  const BatchInsert(this.table, this.values, this.replace);
}

class BatchUpdate extends BatchOperation {
  final String table;
  final Map<String, Object?> values;
  final String? where;
  final List<Object?>? whereArgs;
  const BatchUpdate(this.table, this.values, this.where, this.whereArgs);
}

class BatchDelete extends BatchOperation {
  final String table;
  final String? where;
  final List<Object?>? whereArgs;
  const BatchDelete(this.table, this.where, this.whereArgs);
}

// ---------------------------------------------------------------------------
// Shared helper functions
// ---------------------------------------------------------------------------

Object? normalizeArg(Object? arg) {
  if (arg == null) return null;
  if (arg is Enum) return arg.name;
  if (arg is DateTime) return arg.toIso8601String();
  return arg;
}

List<Object?>? normalizeArgs(List<Object?>? args) {
  if (args == null) return null;
  return args.map(normalizeArg).toList();
}

Map<String, Object?> normalizeMap(Map<String, Object?> map) {
  return map.map((key, value) => MapEntry(key, normalizeArg(value)));
}

// ---------------------------------------------------------------------------
// Abstract DatabaseIsolate interface
// ---------------------------------------------------------------------------

/// Abstract database backend. Concrete implementations:
///   - `database_isolate_io.dart` — uses dart:isolate + sqlite3 (native)
///   - `database_isolate_web.dart` — uses sqlite3_web WASM (Flutter Web)
abstract interface class DatabaseIsolate {
  /// Stream of table names that have been modified
  Stream<String> get changeStream;

  /// Registers custom SQL functions before [start]/[open]
  void registerFunctions(List<SqlFunction> functions);

  /// Starts / initialises the backend
  Future<void> start();

  /// Opens a SQLite file (or ':memory:' for in-memory)
  /// If [password] is provided, it executes `PRAGMA key = ...` immediately after opening (for SQLCipher).
  Future<void> open(String path, {String? password});

  /// Closes the database connection
  Future<void> close();

  /// Executes a DDL/DML statement
  Future<void> execute(String sql, [List<Object?>? args]);

  /// Executes a SELECT query and returns rows as maps
  Future<List<Map<String, Object?>>> query(String sql, [List<Object?>? args]);

  /// Inserts a row and returns the new row-id
  Future<int> insert(String table, Map<String, Object?> values);

  /// Updates rows and returns the number of affected rows
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// Deletes rows and returns the number of affected rows
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  /// Executes a list of commands inside a transaction
  Future<T> transaction<T>(List<DatabaseCommand> commands);

  /// Sends a batch of operations and returns the affected row count
  Future<int> sendBatchCommand(List<BatchOperation> operations);

  /// Gets the SQLite user_version pragma
  Future<int> getVersion();

  /// Sets the SQLite user_version pragma
  Future<void> setVersion(int version);

  /// Shuts down the backend
  Future<void> stop();

  /// Creates a [BatchBuilder] attached to this backend
  BatchBuilder createBatch() => BatchBuilder(this);
}

/// Batch builder for collecting operations before committing them
class BatchBuilder {
  final DatabaseIsolate _db;
  final List<BatchOperation> _operations = [];

  BatchBuilder(this._db);

  void insert(String table, Map<String, Object?> values,
      {bool replace = false}) {
    _operations.add(BatchInsert(table, values, replace));
  }

  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    _operations.add(BatchUpdate(table, values, where, whereArgs));
  }

  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _operations.add(BatchDelete(table, where, whereArgs));
  }

  Future<List<Object?>> commit({bool noResult = false}) async {
    final count = await _db.sendBatchCommand(_operations);
    return noResult ? [] : List.filled(count, null);
  }
}
