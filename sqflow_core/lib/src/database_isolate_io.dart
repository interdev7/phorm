// Native IO implementation of DatabaseIsolate.
// Uses dart:isolate to run sqlite3 in a background thread so that
// long-running SQL operations don't block the main/UI thread.
import 'dart:async';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import 'database_isolate_common.dart';
import 'sql_function.dart';

// ---------------------------------------------------------------------------
// Function registry (lives in the isolate memory space)
// ---------------------------------------------------------------------------

class _FunctionRegistry {
  static final Map<String, SqlFunction> _functions = {};

  static void registerAll(List<SqlFunction> functions) {
    for (final fn in functions) {
      _functions[fn.name] = fn;
    }
  }

  static void applyToDatabase(Database db) {
    for (final fn in _functions.values) {
      db.createFunction(
        functionName: fn.name,
        argumentCount: AllowedArgumentCount(fn.argumentCount),
        function: (args) => fn.function(args),
        deterministic: fn.deterministic,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Response / message wrappers for isolate communication
// ---------------------------------------------------------------------------

class _DatabaseResponse {
  final Object? result;
  final Object? error;
  final StackTrace? stackTrace;

  const _DatabaseResponse({this.result, this.error, this.stackTrace});

  bool get isError => error != null;
}

class _IsolateMessage {
  final DatabaseCommand command;
  final SendPort responsePort;
  const _IsolateMessage(this.command, this.responsePort);
}

// ---------------------------------------------------------------------------
// Concrete native DatabaseIsolate
// ---------------------------------------------------------------------------

/// Native implementation of [DatabaseIsolate].
/// Runs sqlite3 in a background Dart isolate so UI never stalls.
class NativeDatabaseIsolate extends DatabaseIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _initCompleter = Completer<void>();
  final List<SqlFunction> _customFunctions = [];

  final _changeController = StreamController<String>.broadcast();
  StreamSubscription<dynamic>? _changeSubscription;

  @override
  Stream<String> get changeStream => _changeController.stream;

  Future<void> get _initialized => _initCompleter.future;

  @override
  void registerFunctions(List<SqlFunction> functions) {
    _customFunctions.addAll(functions);
  }

  @override
  Future<void> start() async {
    if (_isolate != null) return;

    final receivePort = ReceivePort();
    final changeReceivePort = ReceivePort();

    _isolate = await Isolate.spawn<Map<String, dynamic>>(
      _isolateEntryPoint,
      {
        'port': receivePort.sendPort,
        'changePort': changeReceivePort.sendPort,
        'functions': _customFunctions,
      },
      debugName: 'SQFlow_DatabaseIsolate',
    );

    _sendPort = await receivePort.first as SendPort;

    _changeSubscription = changeReceivePort.listen((message) {
      if (message is String) _changeController.add(message);
    });

    _initCompleter.complete();
  }

  Future<T> _sendCommand<T>(DatabaseCommand command) async {
    await _initialized;
    if (_sendPort == null) throw StateError('Isolate not started');

    final responsePort = ReceivePort();
    _sendPort!.send(_IsolateMessage(command, responsePort.sendPort));

    final response = await responsePort.first as _DatabaseResponse;
    if (response.isError) {
      Error.throwWithStackTrace(
          response.error!, response.stackTrace ?? StackTrace.current);
    }
    return response.result as T;
  }

  @override
  Future<void> open(String path) => _sendCommand(OpenCommand(path));

  @override
  Future<void> close() => _sendCommand(const CloseCommand());

  @override
  Future<void> execute(String sql, [List<Object?>? args]) =>
      _sendCommand(ExecuteCommand(sql, args));

  @override
  Future<List<Map<String, Object?>>> query(String sql, [List<Object?>? args]) =>
      _sendCommand(QueryCommand(sql, args));

  @override
  Future<int> insert(String table, Map<String, Object?> values) =>
      _sendCommand<int>(InsertCommand(table, values));

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      _sendCommand<int>(UpdateCommand(table, values, where, whereArgs));

  @override
  Future<int> delete(String table,
          {String? where, List<Object?>? whereArgs}) =>
      _sendCommand<int>(DeleteCommand(table, where, whereArgs));

  @override
  Future<T> transaction<T>(List<DatabaseCommand> commands) =>
      _sendCommand<T>(TransactionCommand(commands));

  @override
  Future<int> sendBatchCommand(List<BatchOperation> operations) =>
      _sendCommand<int>(BatchCommand(operations));

  @override
  Future<int> getVersion() =>
      _sendCommand<int>(const GetVersionCommand());

  @override
  Future<void> setVersion(int version) =>
      _sendCommand(SetVersionCommand(version));

  @override
  Future<void> stop() async {
    if (_isolate == null) return;
    await close();
    await _changeSubscription?.cancel();
    await _changeController.close();
    _isolate!.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
  }
}

// ---------------------------------------------------------------------------
// Factory function — used by database_isolate.dart (conditional import)
// ---------------------------------------------------------------------------

/// Creates the native isolate-based [DatabaseIsolate].
DatabaseIsolate createDatabaseIsolate() => NativeDatabaseIsolate();

// ---------------------------------------------------------------------------
// Isolate entry point (top-level so it can be spawned)
// ---------------------------------------------------------------------------

void _isolateEntryPoint(Map<String, dynamic> args) {
  final mainPort   = args['port']      as SendPort;
  final changePort = args['changePort'] as SendPort;
  final functions  = args['functions']  as List<SqlFunction>;

  _FunctionRegistry.registerAll(functions);

  final receivePort = ReceivePort();
  mainPort.send(receivePort.sendPort);

  Database? db;
  StreamSubscription<SqliteUpdate>? updatesSub;

  receivePort.listen((message) {
    if (message is! _IsolateMessage) return;

    try {
      final result = _handle(
        message.command,
        db,
        (d) => db = d,
        changePort,
        updatesSub,
        (s) => updatesSub = s,
      );
      message.responsePort.send(_DatabaseResponse(result: result));
    } catch (e, st) {
      message.responsePort.send(_DatabaseResponse(error: e, stackTrace: st));
    }
  });
}

// ---------------------------------------------------------------------------
// Command dispatcher (runs inside the isolate)
// ---------------------------------------------------------------------------

Object? _handle(
  DatabaseCommand command,
  Database? db,
  void Function(Database?) setDb,
  SendPort changePort,
  StreamSubscription<SqliteUpdate>? updatesSub,
  void Function(StreamSubscription<SqliteUpdate>?) setSub,
) {
  switch (command) {
    case OpenCommand(:final path):
      if (db != null) {
        updatesSub?.cancel();
        setSub(null);
        db.dispose();
      }
      final newDb = sqlite3.open(path);
      _FunctionRegistry.applyToDatabase(newDb);
      setSub(newDb.updatesSync.listen((u) => changePort.send(u.tableName)));
      setDb(newDb);
      return null;

    case CloseCommand():
      updatesSub?.cancel();
      setSub(null);
      db?.dispose();
      setDb(null);
      return null;

    case ExecuteCommand(:final sql, :final args):
      if (db == null) throw StateError('Database not opened');
      final na = normalizeArgs(args);
      if (na == null || na.isEmpty) {
        db.execute(sql);
      } else {
        final stmt = db.prepare(sql);
        try { stmt.execute(na); } finally { stmt.dispose(); }
      }
      return null;

    case QueryCommand(:final sql, :final args):
      if (db == null) throw StateError('Database not opened');
      final na = normalizeArgs(args);
      final ResultSet rs;
      if (na == null || na.isEmpty) {
        rs = db.select(sql);
      } else {
        final stmt = db.prepare(sql);
        try { rs = stmt.select(na); } finally { stmt.dispose(); }
      }
      // Convert sqlite3 Row objects to plain maps before sending across isolate boundary
      return rs.map((row) {
        final map = <String, Object?>{};
        for (final key in row.keys) {
          map[key] = row[key];
        }
        return map;
      }).toList();

    case InsertCommand(:final table, :final values):
      if (db == null) throw StateError('Database not opened');
      final nv = normalizeMap(values);
      final cols = nv.keys.toList();
      final ph   = List.filled(cols.length, '?').join(', ');
      final stmt = db.prepare(
          'INSERT INTO $table (${cols.join(', ')}) VALUES ($ph)');
      try { stmt.execute(cols.map((c) => nv[c]).toList()); }
      finally { stmt.dispose(); }
      return db.lastInsertRowId;

    case UpdateCommand(:final table, :final values, :final where, :final whereArgs):
      if (db == null) throw StateError('Database not opened');
      final nv = normalizeMap(values);
      final nw = normalizeArgs(whereArgs);
      final setClauses = nv.keys.map((k) => '$k = ?').join(', ');
      final sql = 'UPDATE $table SET $setClauses'
          '${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try { stmt.execute([...nv.values, ...?nw]); }
      finally { stmt.dispose(); }
      return db.updatedRows;

    case DeleteCommand(:final table, :final where, :final whereArgs):
      if (db == null) throw StateError('Database not opened');
      final nw = normalizeArgs(whereArgs);
      final sql = 'DELETE FROM $table'
          '${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try { stmt.execute(nw ?? []); }
      finally { stmt.dispose(); }
      return db.updatedRows;

    case BatchCommand(:final operations):
      if (db == null) throw StateError('Database not opened');
      db.execute('BEGIN');
      try {
        for (final op in operations) { _handleBatch(db, op); }
        db.execute('COMMIT');
      } catch (e) {
        db.execute('ROLLBACK');
        rethrow;
      }
      return operations.length;

    case TransactionCommand(:final commands):
      if (db == null) throw StateError('Database not opened');
      db.execute('BEGIN');
      try {
        Object? last;
        for (final cmd in commands) {
          last = _handle(cmd, db, (_) {}, changePort, updatesSub, (_) {});
        }
        db.execute('COMMIT');
        return last;
      } catch (e) {
        db.execute('ROLLBACK');
        rethrow;
      }

    case GetVersionCommand():
      if (db == null) throw StateError('Database not opened');
      return db.select('PRAGMA user_version').first['user_version'] as int;

    case SetVersionCommand(:final version):
      if (db == null) throw StateError('Database not opened');
      db.execute('PRAGMA user_version = $version');
      return null;
  }
}

void _handleBatch(Database db, BatchOperation op) {
  switch (op) {
    case BatchInsert(:final table, :final values, :final replace):
      final nv   = normalizeMap(values);
      final cols = nv.keys.toList();
      final ph   = List.filled(cols.length, '?').join(', ');
      final verb = replace ? 'INSERT OR REPLACE' : 'INSERT';
      final stmt = db.prepare(
          '$verb INTO $table (${cols.join(', ')}) VALUES ($ph)');
      try { stmt.execute(cols.map((c) => nv[c]).toList()); }
      finally { stmt.dispose(); }

    case BatchUpdate(:final table, :final values, :final where, :final whereArgs):
      final nv  = normalizeMap(values);
      final nw  = normalizeArgs(whereArgs);
      final set = nv.keys.map((k) => '$k = ?').join(', ');
      final sql = 'UPDATE $table SET $set'
          '${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try { stmt.execute([...nv.values, ...?nw]); }
      finally { stmt.dispose(); }

    case BatchDelete(:final table, :final where, :final whereArgs):
      final nw  = normalizeArgs(whereArgs);
      final sql = 'DELETE FROM $table'
          '${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try { stmt.execute(nw ?? []); }
      finally { stmt.dispose(); }
  }
}
