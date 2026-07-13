// Web/WASM implementation of DatabaseIsolate.
// Uses sqlite3_web (WasmSqlite3) — no dart:isolate, no native libraries needed.
// The WASM binary must be served at /sqlite3.wasm from your Flutter Web app.
//
// Add to your web/index.html (or use a Flutter web plugin loader):
//   <script src="sqlite3.wasm" type="application/wasm"></script>
//
// Download the binary from:
//   https://github.com/simolus3/sqlite3.dart/releases (sqlite3.wasm)
import 'dart:async';
import 'dart:developer';

import 'package:sqlite3/wasm.dart';

import 'database_isolate_common.dart';
import 'sql_function.dart';

// ---------------------------------------------------------------------------
// Concrete Web DatabaseIsolate
// ---------------------------------------------------------------------------

/// Web/WASM implementation of [DatabaseIsolate].
///
/// Runs SQLite synchronously on the main thread (no isolates on Web).
/// For heavy workloads, consider using a SharedWorker — that is an optional
/// future optimisation and is NOT required for correctness.
class WebDatabaseIsolate implements DatabaseIsolate {
  CommonDatabase? _db;
  final List<SqlFunction> _customFunctions = [];

  final _changeController = StreamController<String>.broadcast();

  @override
  Stream<String> get changeStream => _changeController.stream;

  @override
  void registerFunctions(List<SqlFunction> functions) {
    _customFunctions.addAll(functions);
  }

  /// On Web, [start] is a no-op — we initialise lazily inside [open].
  @override
  Future<void> start() async {}

  @override
  Future<void> open(String path, {String? password}) async {
    if (password != null) {
      log(
        'Warning: phorm password/encryption is not supported on Web (WasmSqlite3 ignores password).',
        name: 'Phorm - SQLite Isolate Web',
      );
    }

    // Load the WASM binary from the app's origin
    final wasm = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));

    final CommonDatabase db;
    if (path == ':memory:') {
      db = wasm.openInMemory();
    } else {
      // Persist data in IndexedDB so it survives page reloads
      final fs = await IndexedDbFileSystem.open(dbName: 'phorm_$path');
      wasm.registerVirtualFileSystem(fs, makeDefault: true);
      db = wasm.open(path);
    }

    // Register custom SQL functions
    for (final fn in _customFunctions) {
      db.createFunction(
        functionName: fn.name,
        argumentCount: AllowedArgumentCount(fn.argumentCount),
        function: fn.function,
        deterministic: fn.deterministic,
      );
    }

    // Forward table-change notifications
    db.updates.listen((update) => _changeController.add(update.tableName));

    _db = db;
  }

  @override
  Future<void> close() async {
    _db?.close();
    _db = null;
  }

  CommonDatabase get _openDb {
    final db = _db;
    if (db == null) throw StateError('Database not opened');
    return db;
  }

  @override
  Future<void> execute(String sql, [List<Object?>? args]) async {
    final db = _openDb;
    final na = normalizeArgs(args);
    if (na == null || na.isEmpty) {
      db.execute(sql);
    } else {
      final stmt = db.prepare(sql);
      try {
        stmt.execute(na);
      } finally {
        stmt.close();
      }
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = _openDb;
    final na = normalizeArgs(args);
    final ResultSet rs;
    if (na == null || na.isEmpty) {
      rs = db.select(sql);
    } else {
      final stmt = db.prepare(sql);
      try {
        rs = stmt.select(na);
      } finally {
        stmt.close();
      }
    }
    return rs.map((row) {
      final map = <String, Object?>{};
      for (final key in row.keys) {
        map[key] = row[key];
      }
      return map;
    }).toList();
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = _openDb;
    final nv = normalizeMap(values);
    final cols = nv.keys.toList();
    final ph = List.filled(cols.length, '?').join(', ');
    final stmt = db.prepare(
      'INSERT INTO $table (${cols.join(', ')}) VALUES ($ph)',
    );
    try {
      stmt.execute(cols.map((c) => nv[c]).toList());
    } finally {
      stmt.close();
    }
    return db.lastInsertRowId;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = _openDb;
    final nv = normalizeMap(values);
    final nw = normalizeArgs(whereArgs);
    final set = nv.keys.map((k) => '$k = ?').join(', ');
    final sql =
        'UPDATE $table SET $set'
        '${where != null ? ' WHERE $where' : ''}';
    final stmt = db.prepare(sql);
    try {
      stmt.execute([...nv.values, ...?nw]);
    } finally {
      stmt.close();
    }
    return db.updatedRows;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = _openDb;
    final nw = normalizeArgs(whereArgs);
    final sql =
        'DELETE FROM $table'
        '${where != null ? ' WHERE $where' : ''}';
    final stmt = db.prepare(sql);
    try {
      stmt.execute(nw ?? []);
    } finally {
      stmt.close();
    }
    return db.updatedRows;
  }

  @override
  Future<T> transaction<T>(List<DatabaseCommand> commands) async {
    final db = _openDb;
    // Cascade is not applicable: BEGIN and COMMIT/ROLLBACK span a try/catch block.
    // ignore: cascade_invocations
    db.execute('BEGIN');
    try {
      Object? last;
      for (final cmd in commands) {
        last = await _dispatchLocal(cmd);
      }
      db.execute('COMMIT');
      return last as T;
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<int> sendBatchCommand(List<BatchOperation> operations) async {
    final db = _openDb;
    // Cascade is not applicable: BEGIN and COMMIT/ROLLBACK span a try/catch block.
    // ignore: cascade_invocations
    db.execute('BEGIN');
    try {
      for (final op in operations) {
        _handleBatch(db, op);
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
    return operations.length;
  }

  @override
  Future<int> getVersion() async {
    return _openDb.select('PRAGMA user_version').first['user_version'] as int;
  }

  @override
  Future<void> setVersion(int version) async {
    _openDb.execute('PRAGMA user_version = $version');
  }

  @override
  Future<void> stop() async {
    await close();
    await _changeController.close();
  }

  /// Dispatches a single command synchronously (used inside transactions)
  Future<Object?> _dispatchLocal(DatabaseCommand command) async {
    switch (command) {
      case ExecuteCommand(:final sql, :final args):
        await execute(sql, args);
        return null;
      case QueryCommand(:final sql, :final args):
        return query(sql, args);
      case InsertCommand(:final table, :final values):
        return insert(table, values);
      case UpdateCommand(
        :final table,
        :final values,
        :final where,
        :final whereArgs,
      ):
        return update(table, values, where: where, whereArgs: whereArgs);
      case DeleteCommand(:final table, :final where, :final whereArgs):
        return delete(table, where: where, whereArgs: whereArgs);
      default:
        throw UnsupportedError(
          'Unsupported command inside transaction: $command',
        );
    }
  }

  @override
  BatchBuilder createBatch() {
    return BatchBuilder(this);
  }
}

void _handleBatch(CommonDatabase db, BatchOperation op) {
  switch (op) {
    case BatchInsert(:final table, :final values, :final replace):
      final nv = normalizeMap(values);
      final cols = nv.keys.toList();
      final ph = List.filled(cols.length, '?').join(', ');
      final verb = replace ? 'INSERT OR REPLACE' : 'INSERT';
      final stmt = db.prepare(
        '$verb INTO $table (${cols.join(', ')}) VALUES ($ph)',
      );
      try {
        stmt.execute(cols.map((c) => nv[c]).toList());
      } finally {
        stmt.close();
      }

    case BatchUpdate(
      :final table,
      :final values,
      :final where,
      :final whereArgs,
    ):
      final nv = normalizeMap(values);
      final nw = normalizeArgs(whereArgs);
      final set = nv.keys.map((k) => '$k = ?').join(', ');
      final sql =
          'UPDATE $table SET $set'
          '${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try {
        stmt.execute([...nv.values, ...?nw]);
      } finally {
        stmt.close();
      }

    case BatchDelete(:final table, :final where, :final whereArgs):
      final nw = normalizeArgs(whereArgs);
      final sql =
          'DELETE FROM $table'
          '${where != null ? ' WHERE $where' : ''}';
      final stmt = db.prepare(sql);
      try {
        stmt.execute(nw ?? []);
      } finally {
        stmt.close();
      }
  }
}

// ---------------------------------------------------------------------------
// Factory function — used by database_isolate.dart (conditional import)
// ---------------------------------------------------------------------------

/// Creates the Web/WASM-based [DatabaseIsolate].
DatabaseIsolate createDatabaseIsolate() => WebDatabaseIsolate();
