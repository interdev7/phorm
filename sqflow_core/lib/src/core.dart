import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

typedef ErrorCallback = void Function(Object, StackTrace);

// =======================================================
// SQFLOW CORE v1.0 🚀
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
class SqflowCore<T extends Model> {
  /// Creates a new SqflowCore instance.
  ///
  /// **Example:**
  /// ```dart
  /// final userService = SqflowCore<User>(table: userTable, dbManager: db);
  /// ```
  SqflowCore({required this.dbManager, required this.table});

  /// The database manager instance for this service.
  final DB dbManager;

  /// The table configuration (name, schema, fromJson, primary key, soft delete)
  final Table<T> table;

  // -------------------------------------------------------
  // DATABASE
  // -------------------------------------------------------

  /// Getter for the underlying SQLite [Database] instance.
  ///
  /// **Usage Note:** Avoid direct access; use CRUD methods instead.
  Future<Database> get database => dbManager.database;

  // -------------------------------------------------------
  // TIMESTAMPS ⏰
  // -------------------------------------------------------

  /// Adds automatic timestamps (`created_at` / `updated_at`) to data if supported.
  Map<String, dynamic> _withTimestamps(
    Map<String, dynamic> json, {
    bool isInsert = false,
  }) {
    if (!table.timestamps) return json;

    final now = DateTime.now().toIso8601String();
    final result = Map<String, dynamic>.from(json);
    if (isInsert) {
      if (result['created_at'] == null) {
        result['created_at'] = now;
      }
    } else {
      result.remove('created_at');
    }
    result['updated_at'] = now;
    return result;
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
  /// final id = await userService.insertAsync(User(id: '1', name: 'John'));
  /// print('Inserted ID: $id');
  /// ```
  Future<int> insertAsync(T item, {DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    return db.insert(
      table.name,
      _withTimestamps(item.toJson(), isInsert: true),
    );
  }

  /// Inserts a single item synchronously (fire-and-forget).
  /// Wraps [insertAsync] with callbacks.
  void insert(T item,
      {void Function(int id)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      final id = await insertAsync(item, executor: executor);
      if (onSuccess != null) onSuccess(id);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  /// Updates a single item asynchronously by primary key.
  /// Automatically updates `updated_at`.
  ///
  /// **Example:**
  /// ```dart
  /// final rows = await userService.updateAsync(User(id: '1', name: 'John Updated'));
  /// print('Updated rows: $rows');
  /// ```
  Future<int> updateAsync(T item, {DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    return db.update(
      table.name,
      _withTimestamps(item.toJson()),
      where: '${table.primaryKey} = ?',
      whereArgs: [item.id],
    );
  }

  /// Updates a single item synchronously.
  void update(T item,
      {void Function(int rows)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      final rows = await updateAsync(item, executor: executor);
      if (onSuccess != null) onSuccess(rows);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  /// Upserts a single item asynchronously (insert or replace on conflict).
  ///
  /// **Example:**
  /// ```dart
  /// await userService.upsertAsync(User(id: '1', name: 'John'));
  /// ```
  Future<void> upsertAsync(T item, {DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    await db.insert(
      table.name,
      _withTimestamps(item.toJson(), isInsert: true),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upserts a single item synchronously.
  void upsert(T item,
      {void Function(Object id)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      await upsertAsync(item, executor: executor);
      if (onSuccess != null) onSuccess(item.id);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  // -------------------------------------------------------
  // DELETE / SOFT DELETE 🗑️
  // -------------------------------------------------------

  /// Deletes a single item asynchronously.
  /// If soft delete enabled, sets `deleted_at`.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.deleteAsync('1'); // soft delete
  /// ```
  Future<int> deleteAsync(Object id,
      {bool force = false, DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    if (!table.paranoid || force) {
      return db.delete(table.name,
          where: '${table.primaryKey} = ?', whereArgs: [id]);
    }
    final now = DateTime.now().toIso8601String();
    return db.update(
      table.name,
      {'deleted_at': now, 'updated_at': now},
      where: '${table.primaryKey} = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a single item synchronously.
  void delete(Object id,
      {bool force = false,
      void Function(int rows)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      final rows = await deleteAsync(id, force: force, executor: executor);
      if (onSuccess != null) onSuccess(rows);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  /// Restores a soft-deleted item asynchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.restoreAsync('1');
  /// ```
  Future<int> restoreAsync(Object id, {DatabaseExecutor? executor}) async {
    if (!table.paranoid) throw StateError('Soft delete not enabled');
    final db = executor ?? await database;
    return db.update(
      table.name,
      {'deleted_at': null, 'updated_at': DateTime.now().toIso8601String()},
      where: '${table.primaryKey} = ?',
      whereArgs: [id],
    );
  }

  /// Restores a soft-deleted item synchronously.
  void restore(Object id,
      {void Function(int rows)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      final rows = await restoreAsync(id, executor: executor);
      if (onSuccess != null) onSuccess(rows);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  // -------------------------------------------------------
  // BULK OPERATIONS 📦
  // -------------------------------------------------------

  /// Inserts multiple items in a batch asynchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.insertBatchAsync([User(id: '1', name: 'John'), User(id: '2', name: 'Jane')]);
  /// ```
  Future<void> insertBatchAsync(List<T> items,
      {DatabaseExecutor? executor}) async {
    if (items.isEmpty) return;
    final db = executor ?? await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(table.name, _withTimestamps(item.toJson(), isInsert: true),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Inserts multiple items in a batch synchronously.
  void insertBatch(List<T> items,
      {void Function(int count)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      await insertBatchAsync(items, executor: executor);
      if (onSuccess != null) onSuccess(items.length);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  /// Updates multiple items in a batch asynchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.updateBatchAsync([User(id: '1', name: 'John'), User(id: '2', name: 'Jane')]);
  /// ```
  Future<void> updateBatchAsync(List<T> items,
      {DatabaseExecutor? executor}) async {
    if (items.isEmpty) return;
    final db = executor ?? await database;
    final batch = db.batch();
    for (final item in items) {
      batch.update(table.name, _withTimestamps(item.toJson()),
          where: '${table.primaryKey} = ?', whereArgs: [item.id]);
    }
    await batch.commit(noResult: true);
  }

  /// Updates multiple items in a batch synchronously.
  void updateBatch(List<T> items,
      {void Function(int count)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      await updateBatchAsync(items, executor: executor);
      if (onSuccess != null) onSuccess(items.length);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  /// Upserts multiple items in a batch asynchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.upsertBatchAsync([User(id: '1', name: 'John'), User(id: '2', name: 'Jane')]);
  /// ```
  Future<void> upsertBatchAsync(List<T> items,
      {DatabaseExecutor? executor}) async {
    if (items.isEmpty) return;
    final db = executor ?? await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(table.name, _withTimestamps(item.toJson(), isInsert: true),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Upserts multiple items in a batch synchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.upsertBatch([User(id: '1', name: 'John'), User(id: '2', name: 'Jane')],
  ///   onSuccess: (count) {
  ///     print('Upserted $count items');
  ///   },
  ///   onError: (e, st) {
  ///     print('Error upserting items: $e');
  ///   }
  /// );
  /// ```
  void upsertBatch(List<T> items,
      {void Function(int count)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      await upsertBatchAsync(items, executor: executor);
      if (onSuccess != null) onSuccess(items.length);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  /// Deletes multiple items in a batch asynchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.deleteBatchAsync(['1', '2']);
  /// ```
  Future<void> deleteBatchAsync(List<Object> ids,
      {bool force = false, DatabaseExecutor? executor}) async {
    if (ids.isEmpty) return;
    final db = executor ?? await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final id in ids) {
      if (!table.paranoid || force) {
        batch.delete(table.name,
            where: '${table.primaryKey} = ?', whereArgs: [id]);
      } else {
        batch.update(table.name, {'deleted_at': now, 'updated_at': now},
            where: '${table.primaryKey} = ?', whereArgs: [id]);
      }
    }
    await batch.commit(noResult: true);
  }

  /// Deletes multiple items in a batch synchronously.
  void deleteBatch(List<Object> ids,
      {bool force = false,
      void Function(int count)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      await deleteBatchAsync(ids, force: force, executor: executor);
      if (onSuccess != null) onSuccess(ids.length);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  /// Restores multiple soft-deleted items in a batch asynchronously.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.restoreBatchAsync(['1', '2']);
  /// ```
  Future<void> restoreBatchAsync(List<Object> ids,
      {DatabaseExecutor? executor}) async {
    if (!table.paranoid) throw StateError('Soft delete not enabled');
    if (ids.isEmpty) return;
    final db = executor ?? await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final id in ids) {
      batch.update(table.name, {'deleted_at': null, 'updated_at': now},
          where: '${table.primaryKey} = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  /// Restores multiple soft-deleted items in a batch synchronously.
  void restoreBatch(List<Object> ids,
      {void Function(int count)? onSuccess,
      ErrorCallback? onError,
      DatabaseExecutor? executor}) async {
    try {
      await restoreBatchAsync(ids, executor: executor);
      if (onSuccess != null) onSuccess(ids.length);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  // -------------------------------------------------------
  // READ 🔍
  // -------------------------------------------------------

  /// Reads a single item asynchronously by primary key.
  ///
  /// **Example:**
  /// ```dart
  /// final user = await userService.readAsync('1', include: ['posts']);
  /// ```
  Future<T?> readAsync(Object id,
      {List<String>? columns,
      Attributes? attributes,
      bool withDeleted = false,
      List<Includable>? include,
      DatabaseExecutor? executor}) async {
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

    final result = await db.rawQuery(sql, where.args);
    if (result.isEmpty) return null;

    final row = _unflattenRow(Map<String, dynamic>.from(result.first));

    return table.fromJson(row);
  }

  /// Reads a single item synchronously with callbacks.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.read('1',
  ///   onSuccess: (user) {
  ///     print('User found: ${user.name}');
  ///   },
  ///   onError: (e, st) {
  ///     print('Error reading user: $e');
  ///   }
  /// );
  /// ```
  void read(Object id,
      {List<String>? columns,
      Attributes? attributes,
      void Function(T)? onSuccess,
      ErrorCallback? onError,
      bool withDeleted = false,
      List<Includable>? include,
      DatabaseExecutor? executor}) async {
    try {
      final item = await readAsync(
        id,
        columns: columns,
        attributes: attributes,
        withDeleted: withDeleted,
        include: include,
        executor: executor,
      );
      if (item != null && onSuccess != null) onSuccess(item);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
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
  Map<String, dynamic> _unflattenRow(Map<String, dynamic> row) {
    final result = <String, dynamic>{};
    row.forEach((key, value) {
      if (key.contains('__')) {
        final parts = key.split('__');
        var current = result;
        for (var i = 0; i < parts.length - 1; i++) {
          final part = parts[i];
          current = current.putIfAbsent(part, () => <String, dynamic>{})
              as Map<String, dynamic>;
        }
        current[parts.last] = _tryParseJson(value);
      } else {
        result[key] = _tryParseJson(value);
      }
    });
    return result;
  }

  dynamic _tryParseJson(dynamic value) {
    if (value is String && (value.startsWith('[') || value.startsWith('{'))) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }
    return value;
  }

  /// Builds a single SQL query for relationships using JOINs and JSON aggregation.
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
  }) {
    final selectFields = <String>[];
    final joins = <String>{};

    // Analyze WhereBuilder for automatic LEFT JOINs (for filtering)
    if (where != null) {
      final joinTableNames = <String>{};
      for (final col in where.usedColumns) {
        if (col.contains('.')) {
          joinTableNames.add(col.split('.').first);
        }
      }

      for (final relName in joinTableNames) {
        final rel = table.relationships.where((r) {
          final model = r.model;
          if (model is String) return model == relName;
          if (model is Type) {
            final relatedTable =
                dbManager.tables.where((t) => t.type == model).firstOrNull;
            return relatedTable?.name == relName;
          }
          return false;
        }).firstOrNull;

        if (rel != null) {
          final relatedTable = _findTable(rel.model);
          if (relatedTable != null) {
            if (rel is HasMany || rel is HasOne) {
              joins.add(
                  'LEFT JOIN ${relatedTable.name} ON ${relatedTable.name}.${rel.foreignKey} = ${table.name}.${rel.localKey}');
            } else if (rel is BelongsTo) {
              joins.add(
                  'LEFT JOIN ${relatedTable.name} ON ${relatedTable.name}.${rel.localKey} = ${table.name}.${rel.foreignKey}');
            }
          }
        }
      }
    }

    // Main table fields
    List<String> effectiveColumns;
    if (attributes != null) {
      effectiveColumns = attributes.apply(table.columns);
    } else if (columns != null && columns.isNotEmpty) {
      effectiveColumns = columns;
    } else {
      effectiveColumns = table.columns;
    }

    if (effectiveColumns.isEmpty) {
      // Fallback to * if no columns specified (though table.columns should have them)
      selectFields.add('${table.name}.*');
    } else {
      selectFields.addAll(effectiveColumns.map((c) => '${table.name}.$c'));
    }

    if (includeTotalCount) {
      selectFields.add('COUNT(*) OVER() AS total_count');
    }

    if (include != null) {
      for (final inc in include) {
        final relName = inc.getTableName(dbManager.tables);
        final rel = table.relationships.where((r) {
          final model = r.model;
          if (model is String) return model == relName;
          if (model is Type) {
            final relatedTable =
                dbManager.tables.where((t) => t.type == model).firstOrNull;
            return relatedTable?.name == relName;
          }
          return false;
        }).firstOrNull;

        if (rel == null) continue;

        final relatedTable = _findTable(rel.model);
        if (relatedTable == null) continue;

        if (rel is HasMany) {
          // JSON Aggregation for HasMany
          final relCols = inc.attributes != null
              ? inc.attributes!.apply(relatedTable.columns)
              : relatedTable.columns;

          final fields = relCols.isNotEmpty
              ? relCols.map((c) => "'$c', ${relatedTable.name}.$c").join(', ')
              : "'id', ${relatedTable.name}.${relatedTable.primaryKey}";

          selectFields.add('''
            (SELECT json_group_array(json_object($fields)) 
             FROM ${relatedTable.name} 
             WHERE ${relatedTable.name}.${rel.foreignKey} = ${table.name}.${rel.localKey}
            ) AS $relName
          ''');
        } else {
          // BelongsTo or HasOne
          final relCols = inc.attributes != null
              ? inc.attributes!.apply(relatedTable.columns)
              : relatedTable.columns;

          final fields = relCols.isNotEmpty
              ? relCols.map((c) => "'$c', ${relatedTable.name}.$c").join(', ')
              : "'id', ${relatedTable.name}.${relatedTable.primaryKey}";

          selectFields.add('''
            (SELECT json_object($fields) 
             FROM ${relatedTable.name} 
             WHERE ${relatedTable.name}.${rel is BelongsTo ? rel.localKey : rel.foreignKey} = ${table.name}.${rel is BelongsTo ? rel.foreignKey : rel.localKey}
            ) AS $relName
          ''');
        }
      }
    }

    var query = 'SELECT ${selectFields.join(', ')} FROM ${table.name}';
    if (joins.isNotEmpty) {
      query += ' ${joins.toList().join(' ')}';
    }
    if (where != null && where.isNotEmpty) {
      query += ' WHERE ${where.build()}';
    }

    if (joins.isNotEmpty) {
      query += ' GROUP BY ${table.name}.${table.primaryKey}';
    }

    if (sort != null) {
      query += ' ORDER BY ${sort.build()}';
    }
    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }
    if (explainQueryPlan) {
      query = 'EXPLAIN QUERY PLAN $query';
    }
    return query;
  }

  /// Checks existence by primary key.
  /// Corrected: properly returns true/false.
  ///
  /// **Example:**
  /// ```dart
  /// final exists = await userService.existsAsync('1');
  /// ```
  Future<bool> existsAsync(Object id,
      {bool withDeleted = false, DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    final where = WhereBuilder().eq(table.primaryKey, id);
    if (table.paranoid && !withDeleted) {
      where.isNull('${table.name}.deleted_at');
    }
    final result = await db.query(table.name,
        columns: [table.primaryKey],
        where: where.build(),
        whereArgs: where.args,
        limit: 1);
    return result.isNotEmpty;
  }

  /// Checks existence synchronously with callbacks.
  ///
  /// **Example:**
  /// ```dart
  /// await userService.exists('1',
  ///   onResult: (exists) {
  ///     print('User exists: $exists');
  ///   },
  ///   onError: (e, st) {
  ///     print('Error checking user existence: $e');
  ///   }
  /// );
  /// ```
  void exists(Object id,
      {void Function(bool exists)? onResult,
      ErrorCallback? onError,
      bool withDeleted = false,
      DatabaseExecutor? executor}) async {
    try {
      final ex =
          await existsAsync(id, withDeleted: withDeleted, executor: executor);
      if (onResult != null) onResult(ex);
    } catch (e, st) {
      if (onError != null) onError(e, st);
    }
  }

  // -------------------------------------------------------
  // READ ALL 🔍
  // -------------------------------------------------------

  /// Shared query execution for [readAll] and [readAllWithCount].
  Future<({List<T> data, int count})> _fetchRows({
    required bool includeTotalCount,
    int limit = 20,
    int offset = 0,
    WhereBuilder? where,
    SortBuilder? sort,
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
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
    );

    final rows = await db.rawQuery(sql, effectiveWhere.args);
    final results =
        rows.map((r) => _unflattenRow(Map<String, dynamic>.from(r))).toList();
    final data = results.map(table.fromJson).toList();
    final count =
        rows.isNotEmpty ? (rows.first['total_count'] as int? ?? 0) : 0;

    return (data: data, count: count);
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
    int limit = 20,
    int offset = 0,
    WhereBuilder? where,
    SortBuilder? sort,
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
  }) async {
    final fetched = await _fetchRows(
      includeTotalCount: false,
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
    int limit = 20,
    int offset = 0,
    WhereBuilder? where,
    SortBuilder? sort,
    List<String>? columns,
    Attributes? attributes,
    bool withDeleted = false,
    bool onlyDeleted = false,
    List<Includable>? include,
    DatabaseExecutor? executor,
  }) async {
    final fetched = await _fetchRows(
      includeTotalCount: true,
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
  Future<R> transaction<R>(Future<R> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }
}
