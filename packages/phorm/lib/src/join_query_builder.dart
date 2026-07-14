import 'package:phorm/phorm.dart';

// =======================================================
// JOIN QUERY BUILDER 🔗
// =======================================================

/// Builds the single-query JSON-aggregation SELECT used to load a model
/// together with its relationship tree (HasOne/HasMany/BelongsTo/ManyToMany)
/// in one round-trip, using database-native JSON functions via [SqlDialect].
///
/// Extracted from [PhormCore]; use [PhormCore.buildJoinQuery] instead of
/// instantiating this directly.
class JoinQueryBuilder {
  /// Creates a builder for [table] using [dbManager]'s dialect and registry.
  JoinQueryBuilder({required this.dbManager, required this.table});

  /// Provides the dialect and the table registry for relationship lookups.
  final PhormDatabase dbManager;

  /// The root table the SELECT is built for.
  final Table table;

  Table? _findTable(dynamic model) {
    if (model is String) {
      return dbManager.tables.where((t) => t.name == model).firstOrNull;
    }
    if (model is Type) {
      return dbManager.tables.where((t) => t.type == model).firstOrNull;
    }
    return null;
  }

  /// Finds the relationship of [owner] whose related table is named [relName].
  Relationship? _findRelationship(Table owner, String relName) {
    return owner.relationships.where((r) {
      final model = r.model;
      if (model is String) return model == relName;
      if (model is Type) {
        final relatedTable =
            dbManager.tables.where((t) => t.type == model).firstOrNull;
        return relatedTable?.name == relName;
      }
      return false;
    }).firstOrNull;
  }

  String _paranoidFilter(Table relatedTable) {
    return relatedTable.paranoid
        ? ' AND ${dbManager.dialect.escapeIdentifier('${relatedTable.name}.deleted_at')} IS NULL'
        : '';
  }

  Map<String, String> _buildJsonObjectFields(
    Table currentTable,
    Attributes? attributes,
    List<Includable>? include,
  ) {
    final d = dbManager.dialect;
    final relCols =
        attributes != null
            ? attributes.apply(currentTable.columns)
            : currentTable.columns;
    final fields = <String, String>{};

    if (relCols.isNotEmpty) {
      for (final c in relCols) {
        // Escape table.column for safe use in all dialects
        fields[c] = d.escapeIdentifier('${currentTable.name}.$c');
      }
    } else {
      fields['id'] = d.escapeIdentifier(
        '${currentTable.name}.${currentTable.primaryKey}',
      );
    }

    if (include == null || include.isEmpty) return fields;

    for (final inc in include) {
      final relName = inc.getTableName(dbManager.tables);
      final rel = _findRelationship(currentTable, relName);
      if (rel == null) continue;

      final relatedTable = _findTable(rel.model);
      if (relatedTable == null) continue;

      final subFields = _buildJsonObjectFields(
        relatedTable,
        inc.attributes,
        inc.include,
      );
      final subJsonObject = d.compileJsonObject(subFields);
      final paranoidFilter = _paranoidFilter(relatedTable);

      if (rel is HasMany) {
        final escRelated = d.escapeIdentifier(relatedTable.name);
        final escForeign = d.escapeIdentifier(
          '${relatedTable.name}.${rel.foreignKey}',
        );
        final escCurrent = d.escapeIdentifier(
          '${currentTable.name}.${rel.localKey}',
        );
        fields[relName] = d.compileJsonArray(
          subJsonObject,
          'FROM $escRelated WHERE $escForeign = $escCurrent$paranoidFilter',
        );
      } else if (rel is ManyToMany) {
        final escRelated = d.escapeIdentifier(relatedTable.name);
        final escPivot = d.escapeIdentifier(rel.pivotTable);
        final escPivotRelated = d.escapeIdentifier(
          '${rel.pivotTable}.${rel.relatedKey}',
        );
        final escRelatedLocal = d.escapeIdentifier(
          '${relatedTable.name}.${rel.relatedLocalKey}',
        );
        final escPivotForeign = d.escapeIdentifier(
          '${rel.pivotTable}.${rel.foreignKey}',
        );
        final escCurrent = d.escapeIdentifier(
          '${currentTable.name}.${rel.localKey}',
        );
        fields[relName] = d.compileJsonArray(
          subJsonObject,
          'FROM $escRelated INNER JOIN $escPivot ON $escPivotRelated = $escRelatedLocal WHERE $escPivotForeign = $escCurrent$paranoidFilter',
        );
      } else {
        final escRelated = d.escapeIdentifier(relatedTable.name);
        final escForeign = d.escapeIdentifier(
          '${relatedTable.name}.${rel is BelongsTo ? rel.localKey : rel.foreignKey}',
        );
        final escCurrent = d.escapeIdentifier(
          '${currentTable.name}.${rel is BelongsTo ? rel.foreignKey : rel.localKey}',
        );
        fields[relName] = '''
          (SELECT $subJsonObject
           FROM $escRelated
           WHERE $escForeign = $escCurrent$paranoidFilter)
        ''';
      }
    }

    return fields;
  }

  /// Collects the LEFT JOINs needed to filter by dotted columns
  /// (`related_table.column`) referenced in [where].
  Set<String> _buildFilterJoins(WhereBuilder? where) {
    final joins = <String>{};
    if (where == null) return joins;

    final joinTableNames = <String>{};
    for (final col in where.usedColumns) {
      if (col.contains('.')) {
        joinTableNames.add(col.split('.').first);
      }
    }

    final d = dbManager.dialect;
    for (final relName in joinTableNames) {
      final rel = _findRelationship(table, relName);
      if (rel == null) continue;

      final relatedTable = _findTable(rel.model);
      if (relatedTable == null) continue;

      final escRelated = d.escapeIdentifier(relatedTable.name);
      if (rel is HasMany || rel is HasOne) {
        final escForeign = d.escapeIdentifier(
          '${relatedTable.name}.${rel.foreignKey}',
        );
        final escLocal = d.escapeIdentifier('${table.name}.${rel.localKey}');
        joins.add('LEFT JOIN $escRelated ON $escForeign = $escLocal');
      } else if (rel is BelongsTo) {
        final escRelatedLocal = d.escapeIdentifier(
          '${relatedTable.name}.${rel.localKey}',
        );
        final escForeign = d.escapeIdentifier(
          '${table.name}.${rel.foreignKey}',
        );
        joins.add('LEFT JOIN $escRelated ON $escRelatedLocal = $escForeign');
      } else if (rel is ManyToMany) {
        final escPivot = d.escapeIdentifier(rel.pivotTable);
        final escPivotForeign = d.escapeIdentifier(
          '${rel.pivotTable}.${rel.foreignKey}',
        );
        final escLocal = d.escapeIdentifier('${table.name}.${rel.localKey}');
        final escRelatedLocal = d.escapeIdentifier(
          '${relatedTable.name}.${rel.relatedLocalKey}',
        );
        final escPivotRelated = d.escapeIdentifier(
          '${rel.pivotTable}.${rel.relatedKey}',
        );
        joins
          ..add('LEFT JOIN $escPivot ON $escPivotForeign = $escLocal')
          ..add('LEFT JOIN $escRelated ON $escRelatedLocal = $escPivotRelated');
      }
    }

    return joins;
  }

  /// Adds the JSON-aggregated subselect for each included relationship
  /// to [selectFields].
  void _addIncludeFields(List<String> selectFields, List<Includable> include) {
    final d = dbManager.dialect;

    for (final inc in include) {
      final relName = inc.getTableName(dbManager.tables);
      final rel = _findRelationship(table, relName);
      if (rel == null) continue;

      final relatedTable = _findTable(rel.model);
      if (relatedTable == null) continue;

      final subFields = _buildJsonObjectFields(
        relatedTable,
        inc.attributes,
        inc.include,
      );
      final subJsonObject = d.compileJsonObject(subFields);
      final paranoidFilter = _paranoidFilter(relatedTable);

      if (rel is HasMany) {
        final escRelated = d.escapeIdentifier(relatedTable.name);
        final escForeign = d.escapeIdentifier(
          '${relatedTable.name}.${rel.foreignKey}',
        );
        final escLocal = d.escapeIdentifier('${table.name}.${rel.localKey}');
        selectFields.add('''
            ${d.compileJsonArray(subJsonObject, 'FROM $escRelated WHERE $escForeign = $escLocal$paranoidFilter')} AS $relName
          ''');
      } else if (rel is ManyToMany) {
        final escRelated = d.escapeIdentifier(relatedTable.name);
        final escPivot = d.escapeIdentifier(rel.pivotTable);
        final escPivotRelated = d.escapeIdentifier(
          '${rel.pivotTable}.${rel.relatedKey}',
        );
        final escRelatedLocal = d.escapeIdentifier(
          '${relatedTable.name}.${rel.relatedLocalKey}',
        );
        final escPivotForeign = d.escapeIdentifier(
          '${rel.pivotTable}.${rel.foreignKey}',
        );
        final escLocal = d.escapeIdentifier('${table.name}.${rel.localKey}');
        selectFields.add('''
            ${d.compileJsonArray(subJsonObject, 'FROM $escRelated INNER JOIN $escPivot ON $escPivotRelated = $escRelatedLocal WHERE $escPivotForeign = $escLocal$paranoidFilter')} AS $relName
          ''');
      } else {
        // BelongsTo or HasOne
        final escRelated = d.escapeIdentifier(relatedTable.name);
        final escForeign = d.escapeIdentifier(
          '${relatedTable.name}.${rel is BelongsTo ? rel.localKey : rel.foreignKey}',
        );
        final escLocal = d.escapeIdentifier(
          '${table.name}.${rel is BelongsTo ? rel.foreignKey : rel.localKey}',
        );
        selectFields.add('''
            (SELECT $subJsonObject
             FROM $escRelated
             WHERE $escForeign = $escLocal$paranoidFilter
            ) AS $relName
          ''');
      }
    }
  }

  /// Builds the complete SELECT with JSON-aggregated relationships.
  String build({
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
    final d = dbManager.dialect;
    final selectFields = <String>[];

    // Automatic LEFT JOINs for filtering on related-table columns
    final joins = _buildFilterJoins(where);

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
      // Fallback: escape table name and use wildcard
      selectFields.add('${d.escapeIdentifier(table.name)}.*');
    } else {
      // Escape every table.column reference
      selectFields.addAll(
        effectiveColumns.map((c) => d.escapeIdentifier('${table.name}.$c')),
      );
    }

    if (includeTotalCount) {
      selectFields.add('COUNT(*) OVER() AS total_count');
    }

    if (include != null) {
      _addIncludeFields(selectFields, include);
    }

    final escTable = d.escapeIdentifier(table.name);
    final selectKeyword = distinct ? 'SELECT DISTINCT' : 'SELECT';
    var query = '$selectKeyword ${selectFields.join(', ')} FROM $escTable';
    if (joins.isNotEmpty) {
      query += ' ${joins.toList().join(' ')}';
    }

    // WHERE and HAVING share one placeholder counter so `$n` dialects
    // number their parameters sequentially across both clauses.
    final paramIndex = ParamIndex();
    if (where != null && where.isNotEmpty) {
      query += ' WHERE ${where.build(d, paramIndex)}';
    }

    if (groupBy != null && groupBy.isNotEmpty) {
      // Explicit grouping requested by the caller wins over the automatic
      // primary-key grouping used to deduplicate joined rows.
      final escaped = groupBy.map(d.escapeIdentifier).join(', ');
      query += ' GROUP BY $escaped';
      if (having != null && having.isNotEmpty) {
        query += ' HAVING ${having.build(d, paramIndex)}';
      }
    } else if (joins.isNotEmpty) {
      query +=
          ' GROUP BY ${d.escapeIdentifier('${table.name}.${table.primaryKey}')}';
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
}
