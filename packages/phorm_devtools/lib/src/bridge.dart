// =======================================================
// PHORM STUDIO DEVTOOLS BRIDGE 🛰️
// =======================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:phorm/phorm.dart';

/// Attaches [db] to the Phorm Studio DevTools bridge.
///
/// Call once per database at application startup. The body runs inside an
/// `assert`, so the whole bridge — service extensions, interceptors and this
/// package's code — is compiled out of release and profile builds.
///
/// ```dart
/// final db = DB(tables: [...]);
/// enablePhormDevtools(db);
/// ```
void enablePhormDevtools(PhormDatabase db, {String? id, String? label}) {
  assert(() {
    PhormDevtoolsBridge.attach(db, id: id, label: label);
    return true;
  }(), 'unreachable: the closure above always returns true');
}

/// One executed query kept in the bridge's ring buffer.
class QueryRecord {
  /// Creates a record of one executed query.
  QueryRecord({
    required this.id,
    required this.dbId,
    required this.sql,
    required this.arguments,
    required this.durationMicros,
    required this.isSlow,
    required this.error,
    required this.timestamp,
  });

  /// Monotonically increasing id, also the ring buffer eviction key.
  final int id;

  /// Id of the database that executed the query.
  final String dbId;

  /// Full SQL text (or action label for high-level operations).
  final String sql;

  /// Stringified bind arguments, if any.
  final String? arguments;

  /// Wall-clock execution time in microseconds.
  final int durationMicros;

  /// Whether the query exceeded the slow-query threshold.
  final bool isSlow;

  /// Error text when the query failed, `null` otherwise.
  final String? error;

  /// When the query finished.
  final DateTime timestamp;

  /// Compact form sent inside `phorm.queryBatch` events (SQL truncated).
  Map<String, Object?> toBatchJson() => {
        'id': id,
        'dbId': dbId,
        'sql': sql.length > PhormDevtoolsBridge.maxEventSqlLength
            ? sql.substring(0, PhormDevtoolsBridge.maxEventSqlLength)
            : sql,
        'truncated': sql.length > PhormDevtoolsBridge.maxEventSqlLength,
        'parameters': arguments,
        'executionTimeMs': durationMicros / 1000,
        'isSlow': isSlow,
        'error': error,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Full form returned by `ext.phorm.getQueryDetails`.
  Map<String, Object?> toDetailsJson() => {
        ...toBatchJson(),
        'sql': sql,
        'truncated': false,
      };
}

/// One live watch stream tracked via [PhormInstrumentation].
class StreamRecord {
  /// Creates a record for a newly created watch stream.
  StreamRecord(this.event) : createdAt = DateTime.now();

  /// The creation event as reported by the core.
  final StreamWatchEvent event;

  /// When the stream got its first listener.
  final DateTime createdAt;

  /// Number of values emitted so far.
  int emitCount = 0;

  /// Serializes the record for `ext.phorm.getActiveStreams`.
  Map<String, Object?> toJson() => {
        'id': 's_${event.id}',
        'kind': event.kind,
        'table': event.table,
        'primaryKey': event.primaryKey?.toString(),
        'dependencies': event.dependencies,
        'createdAt': createdAt.toIso8601String(),
        'emitCount': emitCount,
      };
}

/// Debug-only bridge between running PHORM databases and the Phorm Studio
/// DevTools extension.
///
/// Registers `ext.phorm.*` service extensions, records executed queries in a
/// bounded ring buffer and forwards them to DevTools in throttled batches.
/// Attach via [enablePhormDevtools]; never construct directly.
class PhormDevtoolsBridge implements PhormInstrumentation {
  PhormDevtoolsBridge._();

  /// Wire protocol version reported by `ext.phorm.getInfo`.
  static const String protocolVersion = '1.0.0';

  /// Maximum number of query records kept in the ring buffer.
  static const int queryBufferSize = 1000;

  /// SQL longer than this is truncated in batch events
  /// (full text stays available via `ext.phorm.getQueryDetails`).
  static const int maxEventSqlLength = 4096;

  /// Minimum interval between `phorm.queryBatch` events.
  static const Duration batchInterval = Duration(milliseconds: 100);

  static PhormDevtoolsBridge? _instance;

  /// The active bridge, or `null` when [enablePhormDevtools] was never called.
  static PhormDevtoolsBridge? get instance => _instance;

  /// Attaches [db], registering service extensions on first use.
  static void attach(PhormDatabase db, {String? id, String? label}) {
    final bridge = _instance ??= PhormDevtoolsBridge._().._registerExtensions();
    bridge._addDatabase(db, id: id, label: label);
    PhormInstrumentation.instance = bridge;
  }

  /// Detaches everything (used by tests; extensions cannot be unregistered).
  static void reset() {
    _instance?._batchTimer?.cancel();
    _instance = null;
    PhormInstrumentation.instance = null;
  }

  final Map<String, PhormDatabase> _databases = {};
  final Map<String, String> _labels = {};
  final Map<PhormDatabase, String> _dbIds = Map.identity();

  final List<QueryRecord?> _queryBuffer =
      List<QueryRecord?>.filled(queryBufferSize, null);
  int _nextQueryId = 0;
  final List<QueryRecord> _pendingBatch = [];
  Timer? _batchTimer;

  final Map<int, StreamRecord> _streams = {};

  final Map<String, Set<String>> _pendingTableChanges = {};
  Timer? _tableChangeTimer;

  void _addDatabase(PhormDatabase db, {String? id, String? label}) {
    final dbId = id ?? (_databases.isEmpty ? 'main' : 'db${_databases.length}');
    _databases[dbId] = db;
    _labels[dbId] = label ?? dbId;
    _dbIds[db] = dbId;
    // Forward table-change notifications to the panel (Live mode).
    db.changeStream.listen((table) {
      if (!developer.extensionStreamHasListener) return;
      _pendingTableChanges.putIfAbsent(dbId, () => <String>{}).add(table);
      _tableChangeTimer ??= Timer(batchInterval, _flushTableChanges);
    });
  }

  void _flushTableChanges() {
    _tableChangeTimer = null;
    if (_pendingTableChanges.isEmpty) return;
    final changes = {
      for (final entry in _pendingTableChanges.entries)
        entry.key: entry.value.toList(growable: false),
    };
    _pendingTableChanges.clear();
    developer.postEvent('phorm.tablesChanged', {'changes': changes});
  }

  // ---------------------------------------------------------------
  // PhormInstrumentation
  // ---------------------------------------------------------------

  @override
  void queryExecuted(PhormDatabase db, QueryEvent event) {
    final record = QueryRecord(
      id: _nextQueryId++,
      dbId: _dbIds[db] ?? 'unknown',
      sql: event.sql,
      arguments: event.arguments?.toString(),
      durationMicros: event.duration.inMicroseconds,
      isSlow: event.isSlow,
      error: event.error?.toString(),
      timestamp: DateTime.now(),
    );
    _queryBuffer[record.id % queryBufferSize] = record;

    // Serialize and post only when the DevTools panel actually listens.
    if (!developer.extensionStreamHasListener) return;
    _pendingBatch.add(record);
    _batchTimer ??= Timer(batchInterval, _flushBatch);
  }

  void _flushBatch() {
    _batchTimer = null;
    if (_pendingBatch.isEmpty) return;
    final events =
        _pendingBatch.map((r) => r.toBatchJson()).toList(growable: false);
    _pendingBatch.clear();
    developer.postEvent('phorm.queryBatch', {'events': events});
  }

  @override
  void streamCreated(StreamWatchEvent event) {
    final record = StreamRecord(event);
    _streams[event.id] = record;
    if (developer.extensionStreamHasListener) {
      developer.postEvent('phorm.streamCreated', record.toJson());
    }
  }

  @override
  void streamEmitted(int id) {
    _streams[id]?.emitCount++;
  }

  @override
  void streamDestroyed(int id) {
    final record = _streams.remove(id);
    if (record != null && developer.extensionStreamHasListener) {
      developer.postEvent('phorm.streamDestroyed', {'id': 's_$id'});
    }
  }

  // ---------------------------------------------------------------
  // Service extensions
  // ---------------------------------------------------------------

  void _registerExtensions() {
    _register('getInfo', handleGetInfo);
    _register('listDatabases', handleListDatabases);
    _register('getTables', handleGetTables);
    _register('queryData', handleQueryData);
    _register('mutateData', handleMutateData);
    _register('rawSql', handleRawSql);
    _register('getMigrations', handleGetMigrations);
    _register('getQueryDetails', handleGetQueryDetails);
    _register('getActiveStreams', handleGetActiveStreams);
  }

  void _register(
    String name,
    Future<Map<String, Object?>> Function(Map<String, String> params) handler,
  ) {
    developer.registerExtension('ext.phorm.$name', (method, params) async {
      try {
        final result = await handler(params);
        return developer.ServiceExtensionResponse.result(jsonEncode(result));
      } on Object catch (e) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode({
            'error': {'code': 'INTERNAL', 'message': e.toString()},
          }),
        );
      }
    });
  }

  Map<String, Object?> _error(String code, String message) => {
        'error': {'code': code, 'message': message},
      };

  PhormDatabase? _db(Map<String, String> params) =>
      _databases[params['dbId'] ?? 'main'];

  Table? _table(PhormDatabase db, String? name) {
    if (name == null) return null;
    for (final table in db.tables) {
      if (table.name == name) return table;
    }
    return null;
  }

  /// `ext.phorm.getInfo`
  Future<Map<String, Object?>> handleGetInfo(Map<String, String> params) async {
    return {
      'protocolVersion': protocolVersion,
      'databases': _databases.keys.toList(),
    };
  }

  /// `ext.phorm.listDatabases`
  Future<Map<String, Object?>> handleListDatabases(
    Map<String, String> params,
  ) async {
    return {
      'databases': [
        for (final entry in _databases.entries)
          {
            'dbId': entry.key,
            'label': _labels[entry.key],
            'dialect': entry.value.dialect.runtimeType.toString(),
            'tableCount': entry.value.tables.length,
          },
      ],
    };
  }

  /// `ext.phorm.getTables`
  Future<Map<String, Object?>> handleGetTables(
    Map<String, String> params,
  ) async {
    final db = _db(params);
    if (db == null) return _error('DB_NOT_FOUND', 'Unknown dbId');
    final executor = await db.executor;
    final tables = <Map<String, Object?>>[];
    for (final table in db.tables) {
      var rowCount = -1;
      try {
        final rows = await executor
            .rawQuery('SELECT COUNT(*) AS c FROM "${table.name}"');
        rowCount = (rows.first['c'] as num?)?.toInt() ?? -1;
      } on Object catch (_) {
        // Table may not exist yet (pre-migration); keep -1.
      }
      tables.add({
        'name': table.name,
        'primaryKey': table.primaryKey,
        'paranoid': table.paranoid,
        'timestamps': table.timestamps,
        'autoIncrement': table.autoIncrement,
        'rowCount': rowCount,
        'columns': table.columns,
        'relations': [
          for (final rel in table.relationships)
            {
              'type': rel.runtimeType.toString(),
              'target': rel.model.toString(),
              'foreignKey': rel.foreignKey,
              'localKey': rel.localKey,
            },
        ],
      });
    }
    return {'tables': tables};
  }

  /// `ext.phorm.queryData`
  Future<Map<String, Object?>> handleQueryData(
    Map<String, String> params,
  ) async {
    final db = _db(params);
    if (db == null) return _error('DB_NOT_FOUND', 'Unknown dbId');
    final table = _table(db, params['table']);
    if (table == null) return _error('TABLE_NOT_FOUND', 'Unknown table');

    final limit = int.tryParse(params['limit'] ?? '') ?? 50;
    final offset = int.tryParse(params['offset'] ?? '') ?? 0;
    final includeDeleted = params['includeDeleted'] == 'true';
    final search = params['searchQuery'];
    final orderBy = params['orderBy'];
    final orderDir =
        (params['orderDir'] ?? 'asc').toLowerCase() == 'desc' ? 'DESC' : 'ASC';

    if (orderBy != null && !table.columns.contains(orderBy)) {
      return _error('BAD_REQUEST', 'Unknown orderBy column: $orderBy');
    }

    final where = <String>[];
    final args = <Object?>[];
    if (table.paranoid && !includeDeleted) {
      where.add('deleted_at IS NULL');
    }
    if (search != null && search.isNotEmpty && table.columns.isNotEmpty) {
      final likes = table.columns
          .map((c) => 'CAST("$c" AS TEXT) LIKE ?')
          .join(' OR ');
      where.add('($likes)');
      args.addAll(List.filled(table.columns.length, '%$search%'));
    }
    final whereSql = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    final orderSql = orderBy == null ? '' : ' ORDER BY "$orderBy" $orderDir';

    final executor = await db.executor;
    final countRows = await executor.rawQuery(
      'SELECT COUNT(*) AS c FROM "${table.name}"$whereSql',
      args,
    );
    final rows = await executor.rawQuery(
      'SELECT * FROM "${table.name}"$whereSql$orderSql LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
    return {
      'totalCount': (countRows.first['c'] as num?)?.toInt() ?? 0,
      'rows': rows,
    };
  }

  /// `ext.phorm.mutateData`
  Future<Map<String, Object?>> handleMutateData(
    Map<String, String> params,
  ) async {
    final db = _db(params);
    if (db == null) return _error('DB_NOT_FOUND', 'Unknown dbId');
    final table = _table(db, params['table']);
    if (table == null) return _error('TABLE_NOT_FOUND', 'Unknown table');
    final action = params['action'];
    final primaryKey = params['primaryKey'];
    final rawData = params['data'];
    final data = rawData == null ? null : jsonDecode(rawData) as Object?;

    final executor = await db.executor;
    final pkWhere = '"${table.primaryKey}" = ?';
    int affected;
    switch (action) {
      case 'insert':
        await executor.insert(
          table.name,
          (data! as Map<String, dynamic>).cast<String, Object?>(),
        );
        affected = 1;
      case 'insertBatch':
        final rows = (data! as List<dynamic>).cast<Map<String, dynamic>>();
        await db.transaction((txn) async {
          for (final row in rows) {
            await txn.insert(table.name, row.cast<String, Object?>());
          }
        });
        affected = rows.length;
      case 'update':
        affected = await executor.update(
          table.name,
          (data! as Map<String, dynamic>).cast<String, Object?>(),
          where: pkWhere,
          whereArgs: [primaryKey],
        );
      case 'delete':
        if (table.paranoid) {
          affected = await executor.update(
            table.name,
            {'deleted_at': DateTime.now().toIso8601String()},
            where: pkWhere,
            whereArgs: [primaryKey],
          );
        } else {
          affected = await executor.delete(
            table.name,
            where: pkWhere,
            whereArgs: [primaryKey],
          );
        }
      case 'hardDelete':
        affected = await executor.delete(
          table.name,
          where: pkWhere,
          whereArgs: [primaryKey],
        );
      case 'restore':
        if (!table.paranoid) {
          return _error('BAD_REQUEST', 'Table is not paranoid');
        }
        affected = await executor.update(
          table.name,
          {'deleted_at': null},
          where: pkWhere,
          whereArgs: [primaryKey],
        );
      default:
        return _error('BAD_REQUEST', 'Unknown action: $action');
    }
    return {'success': true, 'affectedRows': affected};
  }

  /// `ext.phorm.rawSql` (debug-only, like the whole bridge)
  Future<Map<String, Object?>> handleRawSql(Map<String, String> params) async {
    final db = _db(params);
    if (db == null) return _error('DB_NOT_FOUND', 'Unknown dbId');
    final sql = params['sql'];
    if (sql == null || sql.trim().isEmpty) {
      return _error('BAD_REQUEST', 'Missing sql');
    }
    final rawParameters = params['parameters'];
    final args = rawParameters == null
        ? null
        : (jsonDecode(rawParameters) as List<dynamic>).cast<Object?>();

    final executor = await db.executor;
    final stopwatch = Stopwatch()..start();
    if (sql.trimLeft().toUpperCase().startsWith('SELECT') ||
        sql.trimLeft().toUpperCase().startsWith('PRAGMA') ||
        sql.trimLeft().toUpperCase().startsWith('EXPLAIN')) {
      final rows = await executor.rawQuery(sql, args);
      return {
        'rows': rows,
        'affectedRows': 0,
        'executionTimeMs': stopwatch.elapsedMicroseconds / 1000,
      };
    }
    await executor.execute(sql, args);
    return {
      'rows': const <Object?>[],
      'affectedRows': -1,
      'executionTimeMs': stopwatch.elapsedMicroseconds / 1000,
    };
  }

  /// `ext.phorm.getMigrations`
  Future<Map<String, Object?>> handleGetMigrations(
    Map<String, String> params,
  ) async {
    final db = _db(params);
    if (db == null) return _error('DB_NOT_FOUND', 'Unknown dbId');
    final executor = await db.executor;
    try {
      final rows = await executor.rawQuery(
        'SELECT * FROM __phorm_migrations ORDER BY version',
      );
      return {'applied': rows};
    } on Object catch (e) {
      return _error('NO_MIGRATIONS_TABLE', e.toString());
    }
  }

  /// `ext.phorm.getQueryDetails`
  Future<Map<String, Object?>> handleGetQueryDetails(
    Map<String, String> params,
  ) async {
    final id = int.tryParse(params['queryId'] ?? '');
    if (id == null) return _error('BAD_REQUEST', 'Missing queryId');
    final record = _queryBuffer[id % queryBufferSize];
    if (record == null || record.id != id) {
      return _error('NOT_FOUND', 'Query evicted from buffer');
    }
    return record.toDetailsJson();
  }

  /// `ext.phorm.getActiveStreams`
  Future<Map<String, Object?>> handleGetActiveStreams(
    Map<String, String> params,
  ) async {
    return {
      'streams':
          _streams.values.map((s) => s.toJson()).toList(growable: false),
    };
  }
}
