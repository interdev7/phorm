import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:phorm/phorm.dart';
import 'package:phorm/src/join_query_builder.dart';

/// Callback signature for reporting errors together with their stack trace.
typedef ErrorCallback = void Function(Object, StackTrace);

/// Contract implemented by [PhormCore]: query building and transactions.
abstract interface class IPhormCore<T extends Model> {
  /// Builds the single-query JSON-aggregation SELECT for [T] and its
  /// relationships. See [PhormCore.buildJoinQuery].
  String getBuildJoinQuery({
    List<String>? columns,
    Attributes? attributes,
    List<Includable>? include,
    WhereBuilder? where,
    SortBuilder? sort,
    int? limit,
    int? offset,
    bool includeTotalCount = false,
    bool explainQueryPlan = false,
    bool distinct = false,
    List<String>? groupBy,
    WhereBuilder? having,
  });

  /// Runs [action] inside a database transaction.
  Future<R> transaction<R>(Future<R> Function(DatabaseExecutor txn) action);
}

// =======================================================
// PHORM CORE v1.0 🚀
// =======================================================
///
/// A flexible, generic CRUD service for SQLite databases in Flutter/Dart.
/// Supports soft deletes, automatic timestamps, batch operations,
/// advanced querying, and schema management. Extend this class for your models (T extends Model).
///
/// **Key Features:**
/// - Lazy database initialization
/// - Automatic `created_at` / `updated_at` handling
/// - Soft delete via `deleted_at` timestamp
/// - Bulk operations in transactions for performance
/// - Integration with [WhereBuilder] and [SortBuilder] for complex queries
/// - Optional indexes and custom onCreate/onUpgrade hooks
class PhormCore<T extends Model> implements IPhormCore<T> {
  /// Creates a new PhormCore instance.
  ///
  /// **Example:**
  /// ```dart
  /// final userService = PhormCore<User>(table: userTable, dbManager: db);
  /// ```
  PhormCore({required this.dbManager, required this.table});

  /// Starts a fluent query chain.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.where(PostTable.title.like('%Hello%')).get();
  /// ```
  PhormQuery<T> where(PhormCondition condition) {
    return PhormQuery<T>(this).where(condition);
  }

  /// Starts an empty fluent query chain (all records).
  PhormQuery<T> get query => PhormQuery<T>(this);

  /// The database manager instance for this service.
  final PhormDatabase dbManager;

  /// The table configuration (name, schema, fromJson, primary key, soft delete)
  final Table<T> table;

  // -------------------------------------------------------
  // DATABASE
  // -------------------------------------------------------

  /// Getter for the underlying [DatabaseExecutor] instance.
  ///
  /// **Usage Note:** Avoid direct access; use CRUD methods instead.
  Future<DatabaseExecutor> get database => dbManager.executor;

  // -------------------------------------------------------
  // TIMESTAMPS ⏰
  // -------------------------------------------------------

  /// Filters data to match table columns and adds automatic timestamps.
  Map<String, dynamic> _prepareDataForDb(
    Map<String, dynamic> json, {
    bool isInsert = false,
  }) {
    final result = <String, dynamic>{};

    for (final col in table.columns) {
      if (json.containsKey(col)) {
        result[col] = json[col];
      }
    }

    if (json.containsKey('deleted_at')) {
      result['deleted_at'] = json['deleted_at'];
    }

    if (!table.timestamps) return result;

    final now = DateTime.now().toUtc().toIso8601String();
    if (isInsert) {
      // Strip autoincrement PK when 0 or null — let SQLite assign it.
      if (table.autoIncrement) {
        final pkValue = result[table.primaryKey];
        if (pkValue == null || pkValue == 0) {
          result.remove(table.primaryKey);
        }
      }

      if (json['created_at'] != null) {
        result['created_at'] = json['created_at'];
      } else {
        result['created_at'] = now;
      }
    } else {
      // Do not update created_at when updating an existing record
      result.remove('created_at');
    }
    result['updated_at'] = now;
    return result;
  }

  /// Safely builds the primary key WHERE clause using the active SQL dialect.
  String _pkWhereClause() {
    final escapedPk = dbManager.dialect.escapeIdentifier(table.primaryKey);
    final placeholder = dbManager.dialect.compilePlaceholder(1);
    return '$escapedPk = $placeholder';
  }

  // -------------------------------------------------------
  // CRUD 📝
  // -------------------------------------------------------

  /// Inserts a single item asynchronously.
  /// Automatically sets timestamps.
  /// Returns the row ID.
  ///
  /// **Example:**
  /// ```dart
  /// final id = await userService.insert(User(id: '1', name: 'John'));
  /// print('Inserted ID: $id');
  /// ```
  Future<int> insert(T item, {DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    final json = _prepareDataForDb(item.toJson(), isInsert: true);
    final res = await dbManager.logAction('INSERT INTO ${table.name}', [
      json,
    ], () => db.insert(table.name, json));
    return res;
  }

  /// Updates a single item asynchronously by primary key.
  /// Automatically updates `updated_at`.
  ///
  /// **Example:**
  /// ```dart
  /// final rows = await userService.update(User(id: '1', name: 'John Updated'));
  /// print('Updated rows: $rows');
  /// ```
  Future<int> update(T item, {DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    final json = _prepareDataForDb(item.toJson());
    final res = await dbManager.logAction(
      'UPDATE ${table.name}',
      [json, item.toJson()[table.primaryKey]],
      () => db.update(
        table.name,
        json,
        where: _pkWhereClause(),
        whereArgs: [item.toJson()[table.primaryKey]],
      ),
    );
    return res;
  }

  /// Upserts a single item asynchronously (insert or replace on conflict).
  ///
  /// **Example:**
  /// ```dart
  /// await userService.upsert(User(id: '1', name: 'John'));
  /// ```
  Future<void> upsert(T item, {DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    final json = _prepareDataForDb(item.toJson(), isInsert: true);
    await dbManager.logAction(
      'UPSERT ${table.name}',
      [json],
      () => db.insert(
        table.name,
        json,
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    );
  }

  // -------------------------------------------------------
  // DELETE / SOFT DELETE 🗑️
  // -------------------------------------------------------

  /// Deletes a single item asynchronously.
  /// If soft delete enabled, sets `deleted_at`.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.delete('1'); // soft delete
  /// ```
  Future<int> delete(
    Object id, {
    bool force = false,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    if (!table.paranoid || force) {
      final res = await dbManager.logAction(
        'DELETE FROM ${table.name}',
        [id],
        () => db.delete(table.name, where: _pkWhereClause(), whereArgs: [id]),
      );
      return res;
    }
    final res = await dbManager.logAction(
      'SOFT DELETE ${table.name}',
      [id],
      () => db.update(
        table.name,
        _prepareDataForDb({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }),
        where: _pkWhereClause(),
        whereArgs: [id],
      ),
    );
    return res;
  }

  /// Restores a soft-deleted item asynchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.restore('1');
  /// ```
  Future<int> restore(Object id, {DatabaseExecutor? executor}) async {
    if (!table.paranoid) throw StateError('Soft delete not enabled');
    final db = executor ?? await database;
    final res = await db.update(
      table.name,
      _prepareDataForDb({'deleted_at': null}),
      where: _pkWhereClause(),
      whereArgs: [id],
    );
    return res;
  }

  // -------------------------------------------------------
  // BULK OPERATIONS 📦
  // -------------------------------------------------------

  /// Inserts multiple items in a batch asynchronously.
  Future<int> insertBatch(List<T> items, {DatabaseExecutor? executor}) async {
    if (items.isEmpty) return 0;
    final db = executor ?? await database;
    final count = await dbManager.logAction(
      'INSERT BATCH ${table.name}',
      [items.length],
      () async {
        final batch = db.batch();
        for (final item in items) {
          batch.insert(
            table.name,
            _prepareDataForDb(item.toJson(), isInsert: true),
          );
        }
        final results = await batch.commit(noResult: true);
        return results.length;
      },
    );
    return count;
  }

  /// Updates multiple items in a batch asynchronously.
  Future<int> updateBatch(List<T> items, {DatabaseExecutor? executor}) async {
    if (items.isEmpty) return 0;
    final db = executor ?? await database;
    final count = await dbManager.logAction(
      'UPDATE BATCH ${table.name}',
      [items.length],
      () async {
        final batch = db.batch();
        for (final item in items) {
          batch.update(
            table.name,
            _prepareDataForDb(item.toJson()),
            where: _pkWhereClause(),
            whereArgs: [item.toJson()[table.primaryKey]],
          );
        }
        final results = await batch.commit(noResult: true);
        return results.length;
      },
    );
    return count;
  }

  /// Upserts multiple items in a batch asynchronously.
  Future<int> upsertBatch(List<T> items, {DatabaseExecutor? executor}) async {
    if (items.isEmpty) return 0;
    final db = executor ?? await database;
    final count = await dbManager.logAction(
      'UPSERT BATCH ${table.name}',
      [items.length],
      () async {
        final batch = db.batch();
        for (final item in items) {
          batch.insert(
            table.name,
            _prepareDataForDb(item.toJson(), isInsert: true),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        final results = await batch.commit(noResult: true);
        return results.length;
      },
    );
    return count;
  }

  /// Deletes multiple items in a batch asynchronously.
  Future<int> deleteBatch(
    List<Object> ids, {
    bool force = false,
    DatabaseExecutor? executor,
  }) async {
    if (ids.isEmpty) return 0;
    final db = executor ?? await database;
    final count = await dbManager.logAction(
      'DELETE BATCH ${table.name}',
      [ids.length],
      () async {
        final batch = db.batch();
        if (!table.paranoid || force) {
          for (final id in ids) {
            batch.delete(table.name, where: _pkWhereClause(), whereArgs: [id]);
          }
        } else {
          for (final id in ids) {
            batch.update(
              table.name,
              _prepareDataForDb({
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
              }),
              where: _pkWhereClause(),
              whereArgs: [id],
            );
          }
        }
        final results = await batch.commit(noResult: true);
        return results.length;
      },
    );
    return count;
  }

  /// Restores multiple soft-deleted items in a batch asynchronously.
  Future<int> restoreBatch(
    List<Object> ids, {
    DatabaseExecutor? executor,
  }) async {
    if (!table.paranoid) {
      throw StateError('Restore not supported on non-paranoid tables.');
    }
    if (ids.isEmpty) return 0;
    final db = executor ?? await database;
    final count = await dbManager.logAction(
      'RESTORE BATCH ${table.name}',
      [ids.length],
      () async {
        final batch = db.batch();
        for (final id in ids) {
          batch.update(
            table.name,
            _prepareDataForDb({'deleted_at': null}),
            where: _pkWhereClause(),
            whereArgs: [id],
          );
        }
        final results = await batch.commit(noResult: true);
        return results.length;
      },
    );
    return count;
  }

  // -------------------------------------------------------
  // READ 🔍
  // -------------------------------------------------------

  /// Reads a single item asynchronously by primary key.
  ///
  /// **Example:**
  /// ```dart
  /// final user = await userService.readOne('1', include: ['posts']);
  /// ```
  Future<T?> readOne(
    Object id, {
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    final where = WhereBuilder().eq(table.primaryKey, id);
    if (table.paranoid && !withDeleted) {
      where.isNull('${table.name}.deleted_at');
    }

    final sql = buildJoinQuery(
      columns: columns,
      attributes: attributes,
      include: include,
      where: where,
      limit: 1,
    );

    final result = await dbManager.logAction(
      sql,
      where.args,
      () => db.rawQuery(sql, where.args),
    );
    if (result.isEmpty) return null;

    final row = _unflattenRow(Map<String, dynamic>.from(result.first));

    return table.fromJson(row);
  }

  Table? _findTable(dynamic model) {
    if (model is String) {
      return dbManager.tables.where((t) => t.name == model).firstOrNull;
    }
    if (model is Type) {
      return dbManager.tables.where((t) => t.type == model).firstOrNull;
    }
    return null;
  }

  /// Unflattens a database row that contains aliased columns from JOINs.
  /// Converts 'table__column' into {'table': {'column': value}}.
  static Map<String, dynamic> _unflattenRow(Map<String, dynamic> row) {
    final result = <String, dynamic>{};
    row.forEach((key, value) {
      if (key.contains('__')) {
        final parts = key.split('__');
        var current = result;
        for (var i = 0; i < parts.length - 1; i++) {
          final part = parts[i];
          current =
              current.putIfAbsent(part, () => <String, dynamic>{})
                  as Map<String, dynamic>;
        }
        current[parts.last] = _tryParseJson(value);
      } else {
        result[key] = _tryParseJson(value);
      }
    });
    return result;
  }

  static dynamic _tryParseJson(dynamic value) {
    if (value is String && (value.startsWith('[') || value.startsWith('{'))) {
      try {
        return jsonDecode(value);
      } on FormatException {
        return value;
      }
    }
    return value;
  }

  /// Builds a single SQL query for relationships using JOINs and JSON aggregation.
  ///
  /// Delegates to [JoinQueryBuilder]; kept here as the public entry point.
  @visibleForTesting
  String buildJoinQuery({
    List<String>? columns,
    Attributes? attributes,
    List<Includable>? include,
    WhereBuilder? where,
    SortBuilder? sort,
    int? limit,
    int? offset,
    bool includeTotalCount = false,
    bool explainQueryPlan = false,
    bool distinct = false,
    List<String>? groupBy,
    WhereBuilder? having,
  }) {
    return JoinQueryBuilder(dbManager: dbManager, table: table).build(
      columns: columns,
      attributes: attributes,
      include: include,
      where: where,
      sort: sort,
      limit: limit,
      offset: offset,
      includeTotalCount: includeTotalCount,
      explainQueryPlan: explainQueryPlan,
      distinct: distinct,
      groupBy: groupBy,
      having: having,
    );
  }

  /// Checks existence by primary key.
  /// Corrected: properly returns true/false.
  ///
  /// **Example:**
  /// ```dart
  /// final exists = await userService.exists('1');
  /// ```
  Future<bool> exists(
    Object id, {
    bool withDeleted = false,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    final where = WhereBuilder().eq(table.primaryKey, id);
    if (table.paranoid && !withDeleted) {
      where.isNull('${table.name}.deleted_at');
    }
    final result = await dbManager.logAction(
      'EXISTS in ${table.name}',
      [id, ...where.args],
      () => db.query(
        table.name,
        columns: [table.primaryKey],
        where: where.build(dbManager.dialect),
        whereArgs: where.args,
        limit: 1,
      ),
    );
    return result.isNotEmpty;
  }

  // -------------------------------------------------------
  // AGGREGATES 📊
  // -------------------------------------------------------

  Future<num> _aggregate(
    String function,
    String column, {
    WhereBuilder? where,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    final d = dbManager.dialect;
    final effectiveWhere = where?.copy() ?? WhereBuilder();
    if (table.paranoid && !effectiveWhere.hasConditionOn('deleted_at')) {
      effectiveWhere.isNull('${table.name}.deleted_at');
    }

    // Escape the column name unless it's a wildcard (*)
    final escColumn = column == '*' ? '*' : d.escapeIdentifier(column);
    final escTable = d.escapeIdentifier(table.name);
    var sql = 'SELECT $function($escColumn) as val FROM $escTable';

    // Add joins if WhereBuilder uses related tables
    if (effectiveWhere.isNotEmpty) {
      final joinTableNames = <String>{};
      for (final col in effectiveWhere.usedColumns) {
        if (col.contains('.')) joinTableNames.add(col.split('.').first);
      }
      for (final relName in joinTableNames) {
        final rel =
            table.relationships
                .where(
                  (r) =>
                      (r.model is String
                          ? r.model == relName
                          : (dbManager.tables
                                  .where((t) => t.type == r.model)
                                  .firstOrNull
                                  ?.name ==
                              relName)),
                )
                .firstOrNull;

        if (rel != null) {
          final relatedTable = _findTable(rel.model);
          if (relatedTable != null) {
            final escRelated = d.escapeIdentifier(relatedTable.name);
            if (rel is HasMany || rel is HasOne) {
              final escForeign = d.escapeIdentifier(
                '${relatedTable.name}.${rel.foreignKey}',
              );
              final escLocal = d.escapeIdentifier(
                '${table.name}.${rel.localKey}',
              );
              sql += ' LEFT JOIN $escRelated ON $escForeign = $escLocal';
            } else if (rel is BelongsTo) {
              final escRelatedLocal = d.escapeIdentifier(
                '${relatedTable.name}.${rel.localKey}',
              );
              final escForeign = d.escapeIdentifier(
                '${table.name}.${rel.foreignKey}',
              );
              sql += ' LEFT JOIN $escRelated ON $escRelatedLocal = $escForeign';
            }
          }
        }
      }

      sql += ' WHERE ${effectiveWhere.build(d)}';
    }

    final result = await dbManager.logAction(
      sql,
      effectiveWhere.args,
      () => db.rawQuery(sql, effectiveWhere.args),
    );
    if (result.isEmpty) return 0;
    return (result.first['val'] as num?) ?? 0;
  }

  /// Calculates the total count of rows matching the given condition.
  ///
  /// **Example:**
  /// ```dart
  /// final total = await userService.count(where: WhereBuilder().gt('age', 18));
  /// ```
  Future<int> count({
    Object? column,
    WhereBuilder? where,
    DatabaseExecutor? executor,
  }) async {
    final colStr = column?.toString() ?? '*';
    final result = await _aggregate(
      'COUNT',
      colStr,
      where: where,
      executor: executor,
    );
    return result.toInt();
  }

  /// Calculates the sum of a specific column.
  ///
  /// **Example:**
  /// ```dart
  /// final totalPoints = await scoreService.sum('points');
  /// ```
  Future<num> sum(
    Object column, {
    WhereBuilder? where,
    DatabaseExecutor? executor,
  }) => _aggregate('SUM', column.toString(), where: where, executor: executor);

  /// Calculates the average of a specific column.
  ///
  /// **Example:**
  /// ```dart
  /// final averageAge = await userService.avg('age');
  /// ```
  Future<num> avg(
    Object column, {
    WhereBuilder? where,
    DatabaseExecutor? executor,
  }) => _aggregate('AVG', column.toString(), where: where, executor: executor);

  /// Finds the minimum value of a specific column.
  ///
  /// **Example:**
  /// ```dart
  /// final minScore = await scoreService.min('score');
  /// ```
  Future<num> min(
    Object column, {
    WhereBuilder? where,
    DatabaseExecutor? executor,
  }) => _aggregate('MIN', column.toString(), where: where, executor: executor);

  /// Finds the maximum value of a specific column.
  ///
  /// **Example:**
  /// ```dart
  /// final maxScore = await scoreService.max('score');
  /// ```
  Future<num> max(
    Object column, {
    WhereBuilder? where,
    DatabaseExecutor? executor,
  }) => _aggregate('MAX', column.toString(), where: where, executor: executor);

  // -------------------------------------------------------
  // READ ALL 🔍
  // -------------------------------------------------------

  /// Executes the join query and returns the raw (unparsed) rows.
  ///
  /// This is the row-level counterpart of [readAll]: the same soft-delete
  /// handling and SQL building, but no model mapping — useful for grouped or
  /// aggregate queries (`groupBy`/`having`) whose rows are not full models.
  Future<List<Map<String, Object?>>> readRows({
    bool includeTotalCount = false,
    int? limit = 20,
    int offset = 0,
    WhereBuilder? where,
    SortBuilder? sort,
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
    bool distinct = false,
    List<String>? groupBy,
    WhereBuilder? having,
  }) async {
    final db = executor ?? await database;
    final effectiveWhere = where?.copy() ?? WhereBuilder();

    if (table.paranoid) {
      if (onlyDeleted) {
        effectiveWhere.isNotNull('${table.name}.deleted_at');
      } else if (!withDeleted && !effectiveWhere.hasConditionOn('deleted_at')) {
        effectiveWhere.isNull('${table.name}.deleted_at');
      }
    }

    final sql = buildJoinQuery(
      columns: columns,
      attributes: attributes,
      include: include,
      where: effectiveWhere,
      sort: sort,
      limit: limit,
      offset: offset,
      includeTotalCount: includeTotalCount,
      distinct: distinct,
      groupBy: groupBy,
      having: having,
    );

    // HAVING arguments bind after the WHERE arguments, matching the
    // placeholder order produced by the shared ParamIndex in buildJoinQuery.
    final args = [...effectiveWhere.args, ...?having?.args];

    return dbManager.logAction(sql, args, () => db.rawQuery(sql, args));
  }

  /// Shared query execution for [readAll] and [readAllWithCount].
  Future<({List<T> data, int count})> _fetchRows({
    required bool includeTotalCount,
    int? limit = 20,
    int offset = 0,
    WhereBuilder? where,
    SortBuilder? sort,
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
    bool distinct = false,
    List<String>? groupBy,
    WhereBuilder? having,
  }) async {
    final rows = await readRows(
      includeTotalCount: includeTotalCount,
      limit: limit,
      offset: offset,
      where: where,
      sort: sort,
      columns: columns,
      attributes: attributes,
      withDeleted: withDeleted,
      onlyDeleted: onlyDeleted,
      include: include,
      executor: executor,
      distinct: distinct,
      groupBy: groupBy,
      having: having,
    );

    List<T> data;
    try {
      final threshold = dbManager.isolateThreshold;
      if (rows.length > threshold) {
        // Use isolate for large datasets to keep UI thread responsive
        // We pass only necessary data to a static method to avoid capturing 'this' or local scope
        data = await _parseInIsolate<T>(rows, table.fromJson, table.name);
      } else {
        data =
            rows.map((r) {
              final unflattened = _unflattenRow(Map<String, dynamic>.from(r));
              return table.fromJson(unflattened);
            }).toList();
      }
    } catch (e, stack) {
      dbManager.logger?.error('Error parsing results', e, stack);
      rethrow;
    }

    final count =
        rows.isNotEmpty ? (rows.first['total_count'] as int? ?? 0) : 0;

    return (data: data, count: count);
  }

  /// Internal helper for parsing rows in a background isolate.
  /// This is a static method to ensure it doesn't capture the instance state (this).
  static Future<List<T>> _parseInIsolate<T extends Model>(
    List<Map<String, Object?>> rows,
    T Function(Map<String, dynamic>) fromJson,
    String tableName,
  ) async {
    return Isolate.run(() {
      return rows.map((r) {
        final unflattened = _unflattenRow(Map<String, dynamic>.from(r));
        return fromJson(unflattened);
      }).toList();
    }, debugName: 'PHORM_IsolateParsing_$tableName');
  }

  /// Returns a page of items without a total count.
  ///
  /// Use [readAllWithCount] when you need the total number of matching rows
  /// for pagination UI.
  ///
  /// **Example:**
  /// ```dart
  /// final result = await userService.readAll(
  ///   where: WhereBuilder().eq('city', 'Sofia'),
  ///   limit: 20,
  ///   sort: SortBuilder().asc('first_name'),
  /// );
  /// for (final user in result.data) { ... }
  /// ```
  Future<Result<T>> readAll({
    int? limit = 20,
    int offset = 0,
    WhereBuilder? where,
    SortBuilder? sort,
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
    bool distinct = false,
  }) async {
    final fetched = await _fetchRows(
      includeTotalCount: false,
      distinct: distinct,
      limit: limit,
      offset: offset,
      where: where,
      sort: sort,
      columns: columns,
      attributes: attributes,
      withDeleted: withDeleted,
      onlyDeleted: onlyDeleted,
      include: include,
      executor: executor,
    );
    return Result(data: fetched.data);
  }

  /// Returns a page of items **with** the total count of matching rows.
  ///
  /// Uses a single SQL query with `COUNT(*) OVER()` — no extra round-trip.
  /// The returned [ResultWithCount.count] reflects the total number of rows
  /// matching the [where] clause, regardless of [limit]/[offset].
  ///
  /// **Example:**
  /// ```dart
  /// final result = await userService.readAllWithCount(
  ///   where: WhereBuilder().eq('city', 'Sofia'),
  ///   limit: 20,
  ///   offset: 0,
  /// );
  /// print('Showing ${result.data.length} of ${result.count}');
  /// ```
  Future<ResultWithCount<T>> readAllWithCount({
    int? limit = 20,
    int offset = 0,
    WhereBuilder? where,
    SortBuilder? sort,
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
    bool distinct = false,
  }) async {
    final fetched = await _fetchRows(
      includeTotalCount: true,
      distinct: distinct,
      limit: limit,
      offset: offset,
      where: where,
      sort: sort,
      columns: columns,
      attributes: attributes,
      withDeleted: withDeleted,
      onlyDeleted: onlyDeleted,
      include: include,
      executor: executor,
    );
    return ResultWithCount(data: fetched.data, count: fetched.count);
  }

  /// Executes operations in a transaction.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.transaction((txn) async {
  ///   await txn.insert('users', {'id': '1', 'name': 'John'});
  ///   await txn.update('users', {'name': 'John Updated'}, where: 'id = ?', whereArgs: ['1']);
  /// });
  /// ```
  @override
  Future<R> transaction<R>(
    Future<R> Function(DatabaseExecutor txn) action,
  ) async {
    return dbManager.transaction(action);
  }

  /// **Internal Helper: Extract tables from Includable list**
  Set<String> _extractIncludedTables(List<Includable>? includes) {
    final tables = <String>{};
    if (includes == null) return tables;
    for (final inc in includes) {
      tables.add(inc.getTableName(dbManager.tables));
      if (inc.include != null) {
        tables.addAll(_extractIncludedTables(inc.include));
      }
    }
    return tables;
  }

  // -------------------------------------------------------
  // WATCHERS (STREAMS) 📡
  // -------------------------------------------------------

  /// Watches a single record by ID.
  /// Re-emits when the table or any specified dependencies change.
  ///
  /// **Parameters:**
  /// - `id`: The primary key of the record.
  /// - `include`: Relationships to eager load.
  /// - `attributes`: Column selection filter.
  /// - `withDeleted`: Whether to include soft-deleted record.
  /// - `dependencies`: Extra table names to watch for changes.
  Stream<T?> watchOne(
    Object id, {
    List<Includable>? include,
    Attributes? attributes,
    bool withDeleted = false,
    List<String>? dependencies,
  }) async* {
    final tablesToWatch = {
      table.name,
      ..._extractIncludedTables(include),
      ...?dependencies,
    };
    // Initial load
    yield await readOne(
      id,
      include: include,
      attributes: attributes,
      withDeleted: withDeleted,
    );

    // Listen for changes
    await for (final changedTable in dbManager.changeStream) {
      if (tablesToWatch.contains(changedTable)) {
        yield await readOne(
          id,
          include: include,
          attributes: attributes,
          withDeleted: withDeleted,
        );
      }
    }
  }

  /// Watches all records matching the filters.
  /// Re-emits when the table or any specified dependencies change.
  ///
  /// **Parameters:**
  /// - `where`: Filter conditions.
  /// - `sort`: Ordering.
  /// - `limit`: Max rows.
  /// - `offset`: Skip rows.
  /// - `include`: Relationships to eager load.
  /// - `attributes`: Column selection filter.
  /// - `withDeleted`: Whether to include soft-deleted records.
  /// - `onlyDeleted`: Return only soft-deleted records.
  /// - `dependencies`: Extra table names to watch for changes.
  Stream<List<T>> watchAll({
    WhereBuilder? where,
    SortBuilder? sort,
    int? limit,
    int? offset,
    List<Includable>? include,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<String>? dependencies,
  }) async* {
    final tablesToWatch = {
      table.name,
      ..._extractIncludedTables(include),
      ...?dependencies,
    };

    // Initial load
    final initial = await readAll(
      where: where,
      sort: sort,
      limit: limit ?? 20,
      offset: offset ?? 0,
      include: include,
      attributes: attributes,
      withDeleted: withDeleted,
      onlyDeleted: onlyDeleted,
    );
    yield initial.data;

    // Listen for changes
    await for (final changedTable in dbManager.changeStream) {
      if (tablesToWatch.contains(changedTable)) {
        final result = await readAll(
          where: where,
          sort: sort,
          limit: limit ?? 20,
          offset: offset ?? 0,
          include: include,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
        );
        yield result.data;
      }
    }
  }

  @override
  String getBuildJoinQuery({
    List<String>? columns,
    Attributes? attributes,
    List<Includable>? include,
    WhereBuilder? where,
    SortBuilder? sort,
    int? limit,
    int? offset,
    bool includeTotalCount = false,
    bool explainQueryPlan = false,
    bool distinct = false,
    List<String>? groupBy,
    WhereBuilder? having,
  }) {
    return buildJoinQuery(
      columns: columns,
      attributes: attributes,
      include: include,
      where: where,
      sort: sort,
      limit: limit,
      offset: offset,
      includeTotalCount: includeTotalCount,
      explainQueryPlan: explainQueryPlan,
      distinct: distinct,
      groupBy: groupBy,
      having: having,
    );
  }
}
