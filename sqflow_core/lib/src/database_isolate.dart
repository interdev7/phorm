import 'dart:async';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

/// Commands that can be sent to the database isolate
sealed class _DatabaseCommand {
  const _DatabaseCommand();
}

class _OpenCommand extends _DatabaseCommand {
  final String path;
  const _OpenCommand(this.path);
}

class _CloseCommand extends _DatabaseCommand {
  const _CloseCommand();
}

class _ExecuteCommand extends _DatabaseCommand {
  final String sql;
  final List<Object?>? args;
  const _ExecuteCommand(this.sql, this.args);
}

class _QueryCommand extends _DatabaseCommand {
  final String sql;
  final List<Object?>? args;
  const _QueryCommand(this.sql, this.args);
}

class _InsertCommand extends _DatabaseCommand {
  final String table;
  final Map<String, Object?> values;
  const _InsertCommand(this.table, this.values);
}

class _UpdateCommand extends _DatabaseCommand {
  final String table;
  final Map<String, Object?> values;
  final String? where;
  final List<Object?>? whereArgs;
  const _UpdateCommand(this.table, this.values, this.where, this.whereArgs);
}

class _DeleteCommand extends _DatabaseCommand {
  final String table;
  final String? where;
  final List<Object?>? whereArgs;
  const _DeleteCommand(this.table, this.where, this.whereArgs);
}

class _BatchCommand extends _DatabaseCommand {
  final List<_BatchOperation> operations;
  const _BatchCommand(this.operations);
}

class _TransactionCommand extends _DatabaseCommand {
  final List<_DatabaseCommand> commands;
  const _TransactionCommand(this.commands);
}

class _GetVersionCommand extends _DatabaseCommand {
  const _GetVersionCommand();
}

class _SetVersionCommand extends _DatabaseCommand {
  final int version;
  const _SetVersionCommand(this.version);
}

/// Batch operation types
sealed class _BatchOperation {
  const _BatchOperation();
}

class _BatchInsert extends _BatchOperation {
  final String table;
  final Map<String, Object?> values;
  final bool replace;
  const _BatchInsert(this.table, this.values, this.replace);
}

class _BatchUpdate extends _BatchOperation {
  final String table;
  final Map<String, Object?> values;
  final String? where;
  final List<Object?>? whereArgs;
  const _BatchUpdate(this.table, this.values, this.where, this.whereArgs);
}

class _BatchDelete extends _BatchOperation {
  final String table;
  final String? where;
  final List<Object?>? whereArgs;
  const _BatchDelete(this.table, this.where, this.whereArgs);
}

/// Response from the database isolate
class _DatabaseResponse {
  final Object? result;
  final Object? error;
  final StackTrace? stackTrace;

  const _DatabaseResponse({this.result, this.error, this.stackTrace});

  bool get isError => error != null;
}

/// Message wrapper for isolate communication
class _IsolateMessage {
  final _DatabaseCommand command;
  final SendPort responsePort;

  const _IsolateMessage(this.command, this.responsePort);
}

/// Database isolate entry point
void _databaseIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  Database? db;

  receivePort.listen((message) {
    if (message is! _IsolateMessage) return;

    final command = message.command;
    final responsePort = message.responsePort;

    try {
      final result = _handleCommand(command, db, (newDb) => db = newDb);
      responsePort.send(_DatabaseResponse(result: result));
    } catch (e, st) {
      responsePort.send(_DatabaseResponse(error: e, stackTrace: st));
    }
  });
}

/// Handles a database command in the isolate
Object? _handleCommand(
  _DatabaseCommand command,
  Database? db,
  void Function(Database?) setDb,
) {
  switch (command) {
    case _OpenCommand(:final path):
      if (db != null) {
        db.dispose();
      }
      final newDb = sqlite3.open(path);
      setDb(newDb);
      return null;

    case _CloseCommand():
      db?.dispose();
      setDb(null);
      return null;

    case _ExecuteCommand(:final sql, :final args):
      if (db == null) throw StateError('Database not opened');
      if (args == null || args.isEmpty) {
        db.execute(sql);
      } else {
        final stmt = db.prepare(sql);
        try {
          stmt.execute(args);
        } finally {
          stmt.dispose();
        }
      }
      return null;

    case _QueryCommand(:final sql, :final args):
      if (db == null) throw StateError('Database not opened');
      final ResultSet resultSet;
      if (args == null || args.isEmpty) {
        resultSet = db.select(sql);
      } else {
        final stmt = db.prepare(sql);
        try {
          resultSet = stmt.select(args);
        } finally {
          stmt.dispose();
        }
      }
      return resultSet.map((row) => row.toMap()).toList();

    case _InsertCommand(:final table, :final values):
      if (db == null) throw StateError('Database not opened');
      final columns = values.keys.toList();
      final placeholders = List.filled(columns.length, '?').join(', ');
      final sql = 'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)';
      final stmt = db.prepare(sql);
      try {
        stmt.execute(columns.map((c) => values[c]).toList());
      } finally {
        stmt.dispose();
      }
      return db.lastInsertRowId;

    case _UpdateCommand(:final table, :final values, :final where, :final whereArgs):
      if (db == null) throw StateError('Database not opened');
      final setClauses = values.keys.map((k) => '$k = ?').join(', ');
      final sql = 'UPDATE $table SET $setClauses${where != null ? ' WHERE $where' : ''}';
      final args = [...values.values, ...?whereArgs];
      final stmt = db.prepare(sql);
      try {
        stmt.execute(args);
      } finally {
        stmt.dispose();
      }
      return db.updatedRows;

    case _DeleteCommand(:final table, :final where, :final whereArgs):
      if (db == null) throw StateError('Database not opened');
      final sql = 'DELETE FROM $table${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try {
        stmt.execute(whereArgs ?? []);
      } finally {
        stmt.dispose();
      }
      return db.updatedRows;

    case _BatchCommand(:final operations):
      if (db == null) throw StateError('Database not opened');
      db.execute('BEGIN');
      try {
        for (final op in operations) {
          _handleBatchOperation(db, op);
        }
        db.execute('COMMIT');
      } catch (e) {
        db.execute('ROLLBACK');
        rethrow;
      }
      return operations.length;

    case _TransactionCommand(:final commands):
      if (db == null) throw StateError('Database not opened');
      db.execute('BEGIN');
      try {
        Object? lastResult;
        for (final cmd in commands) {
          lastResult = _handleCommand(cmd, db, (_) {});
        }
        db.execute('COMMIT');
        return lastResult;
      } catch (e) {
        db.execute('ROLLBACK');
        rethrow;
      }

    case _GetVersionCommand():
      if (db == null) throw StateError('Database not opened');
      final result = db.select('PRAGMA user_version');
      return result.first['user_version'] as int;

    case _SetVersionCommand(:final version):
      if (db == null) throw StateError('Database not opened');
      db.execute('PRAGMA user_version = $version');
      return null;
  }
}

void _handleBatchOperation(Database db, _BatchOperation op) {
  switch (op) {
    case _BatchInsert(:final table, :final values, :final replace):
      final columns = values.keys.toList();
      final placeholders = List.filled(columns.length, '?').join(', ');
      final sql = '${replace ? 'INSERT OR REPLACE' : 'INSERT'} INTO $table (${columns.join(', ')}) VALUES ($placeholders)';
      final stmt = db.prepare(sql);
      try {
        stmt.execute(columns.map((c) => values[c]).toList());
      } finally {
        stmt.dispose();
      }

    case _BatchUpdate(:final table, :final values, :final where, :final whereArgs):
      final setClauses = values.keys.map((k) => '$k = ?').join(', ');
      final sql = 'UPDATE $table SET $setClauses${where != null ? ' WHERE $where' : ''}';
      final args = [...values.values, ...?whereArgs];
      final stmt = db.prepare(sql);
      try {
        stmt.execute(args);
      } finally {
        stmt.dispose();
      }

    case _BatchDelete(:final table, :final where, :final whereArgs):
      final sql = 'DELETE FROM $table${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try {
        stmt.execute(whereArgs ?? []);
      } finally {
        stmt.dispose();
      }
  }
}

/// Database isolate wrapper that provides async API over synchronous sqlite3
class DatabaseIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _initCompleter = Completer<void>();

  Future<void> get initialized => _initCompleter.future;

  /// Starts the database isolate
  Future<void> start() async {
    if (_isolate != null) return;

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _databaseIsolateEntryPoint,
      receivePort.sendPort,
      debugName: 'SQFlow_DatabaseIsolate',
    );

    _sendPort = await receivePort.first as SendPort;
    _initCompleter.complete();
  }

  /// Sends a command to the isolate and waits for response
  Future<T> _sendCommand<T>(_DatabaseCommand command) async {
    await initialized;
    if (_sendPort == null) throw StateError('Isolate not started');

    final responsePort = ReceivePort();
    _sendPort!.send(_IsolateMessage(command, responsePort.sendPort));

    final response = await responsePort.first as _DatabaseResponse;
    if (response.isError) {
      Error.throwWithStackTrace(response.error!, response.stackTrace ?? StackTrace.current);
    }

    return response.result as T;
  }

  /// Opens a database file
  Future<void> open(String path) => _sendCommand(_OpenCommand(path));

  /// Closes the database
  Future<void> close() => _sendCommand(const _CloseCommand());

  /// Executes a SQL statement
  Future<void> execute(String sql, [List<Object?>? args]) =>
      _sendCommand(_ExecuteCommand(sql, args));

  /// Executes a query and returns results
  Future<List<Map<String, Object?>>> query(String sql, [List<Object?>? args]) =>
      _sendCommand(_QueryCommand(sql, args));

  /// Inserts a row and returns the row ID
  Future<int> insert(String table, Map<String, Object?> values) =>
      _sendCommand<int>(_InsertCommand(table, values));

  /// Updates rows and returns the number of affected rows
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      _sendCommand<int>(_UpdateCommand(table, values, where, whereArgs));

  /// Deletes rows and returns the number of affected rows
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _sendCommand<int>(_DeleteCommand(table, where, whereArgs));

  /// Executes commands in a transaction
  Future<T> transaction<T>(List<_DatabaseCommand> commands) =>
      _sendCommand<T>(_TransactionCommand(commands));

  /// Creates a batch builder
  BatchBuilder createBatch() => BatchBuilder(this);

  /// Gets the database version
  Future<int> getVersion() => _sendCommand<int>(const _GetVersionCommand());

  /// Sets the database version
  Future<void> setVersion(int version) => _sendCommand(_SetVersionCommand(version));

  /// Stops the isolate
  Future<void> stop() async {
    if (_isolate == null) return;
    await close();
    _isolate!.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
  }
}

/// Batch builder for collecting operations
class BatchBuilder {
  final DatabaseIsolate _db;
  final List<_BatchOperation> _operations = [];

  BatchBuilder(this._db);

  void insert(String table, Map<String, Object?> values, {bool replace = false}) {
    _operations.add(_BatchInsert(table, values, replace));
  }

  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    _operations.add(_BatchUpdate(table, values, where, whereArgs));
  }

  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _operations.add(_BatchDelete(table, where, whereArgs));
  }

  Future<List<Object?>> commit({bool noResult = false}) async {
    final count = await _db._sendCommand<int>(_BatchCommand(_operations));
    return noResult ? [] : List.filled(count, null);
  }
}

/// Extension to convert Row to Map
extension _RowToMap on Row {
  Map<String, Object?> toMap() {
    final map = <String, Object?>{};
    final cols = keys.toList();
    for (var i = 0; i < cols.length; i++) {
      map[cols[i]] = this[cols[i]];
    }
    return map;
  }
}
