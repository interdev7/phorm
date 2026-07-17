import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/schema_generator.dart';
import 'metadata_extractor.dart';
import 'string_schema_builder.dart';

// Generator works with any ISqlValidator via its `sql` field.
// No concrete checker classes needed — users define their own validators.

class PhormSchemaGenerator extends GeneratorForAnnotation<Schema> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final schemaReader = annotation;
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Only classes can be annotated with @Schema',
        element: element,
      );
    }

    final className = element.name ?? '';
    final tableName =
        schemaReader.peek('tableName')?.stringValue ?? _camelToSnake(className);
    final useFromJson = schemaReader.peek('useFromJson')?.boolValue ?? true;

    final strategyReader = schemaReader.peek('columnNaming');
    final strategy =
        strategyReader == null || strategyReader.isNull
            ? ColumnNamingStrategy.snakeCase
            : ColumnNamingStrategy.values.firstWhere(
              (e) => e.name == strategyReader.revive().accessor.split('.').last,
              // coverage:ignore-start
              orElse:
                  () =>
                      throw InvalidGenerationSourceError(
                        'Unknown ColumnNamingStrategy value',
                        element: element,
                      ),
              // coverage:ignore-end
            );

    final dialectReader = schemaReader.peek('dialect');
    final dialectKind =
        dialectReader == null || dialectReader.isNull
            ? SqlDialectKind.sqlite
            : SqlDialectKind.values.firstWhere(
              (e) => e.name == dialectReader.revive().accessor.split('.').last,
              // coverage:ignore-start
              orElse: () => SqlDialectKind.sqlite,
              // coverage:ignore-end
            );
    final dialect = SchemaGenerator.fromKind(dialectKind);

    final timestamps = schemaReader.peek('timestamps')?.boolValue ?? true;
    final paranoid = schemaReader.peek('paranoid')?.boolValue ?? false;

    final fileName = p.basename(buildStep.inputId.path);

    final fields = element.fields.where((f) => !f.isStatic).toList();

    final columnSql = <String>[];
    final columnNames = <String>[];
    final foreignKeys = <String>[];

    bool hasCreatedAt = false;
    bool hasUpdatedAt = false;
    bool hasDeletedAt = false;
    String primaryKey = 'id';
    // SQL type of the owning model's primary key. Used when synthesizing the
    // foreign-key column of an auto-generated pivot table.
    String primaryKeySqlType = 'TEXT';

    for (final field in fields) {
      final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
      if (sqlName == 'created_at') hasCreatedAt = true;
      if (sqlName == 'updated_at') hasUpdatedAt = true;
      if (sqlName == 'deleted_at') hasDeletedAt = true;

      final annotationMeta =
          field.metadata.annotations.where((m) {
            final name = m.element?.enclosingElement?.name;
            return name == 'Column' || name == 'ID';
          }).firstOrNull;

      if (annotationMeta != null &&
          annotationMeta.element?.enclosingElement?.name == 'ID') {
        primaryKey = sqlName;
        primaryKeySqlType = MetadataExtractor.resolveSqlType(field, dialect);
      }

      if (annotationMeta == null) continue;

      final result = _generateColumn(field, annotationMeta, strategy, dialect);
      columnSql.add(result.columnSql);
      columnNames.add(result.columnName);
    }

    final tsType = dialect.timestampColumnType();
    if (timestamps) {
      if (!hasCreatedAt) {
        columnSql.add('  created_at $tsType NOT NULL');
        columnNames.add('created_at');
      }
      if (!hasUpdatedAt) {
        columnSql.add('  updated_at $tsType NOT NULL');
        columnNames.add('updated_at');
      }
    }

    if (paranoid && !hasDeletedAt) {
      columnSql.add('  deleted_at $tsType');
      columnNames.add('deleted_at');
    }
    if (columnSql.isEmpty) {
      throw InvalidGenerationSourceError(
        'Class $className has no columns',
        element: element,
      );
    }

    String indexSql = _generateIndexes(schemaReader, tableName);

    if (timestamps || hasUpdatedAt) {
      final triggerSql = dialect.updatedAtTimestampDdl(tableName);
      if (triggerSql != null && triggerSql.isNotEmpty) {
        if (indexSql.isNotEmpty) {
          indexSql += '\n$triggerSql';
        } else {
          indexSql = triggerSql;
        }
      }
    }

    final List<Map<String, dynamic>> relationships = [
      ..._extractRelationships(schemaReader, dialect),
    ];

    // Also scan fields for @BelongsTo, @HasMany, @HasOne, @Join
    for (final field in fields) {
      final fieldMeta =
          field.metadata.annotations.where((m) {
            final name = m.element?.enclosingElement?.name;
            return name == 'BelongsTo' ||
                name == 'HasMany' ||
                name == 'HasOne' ||
                name == 'Join';
          }).firstOrNull;

      if (fieldMeta != null) {
        relationships.add(_parseRelationship(fieldMeta, dialect));
      }
    }

    // Synthesize missing foreign key columns and add constraints
    for (final rel in relationships) {
      if (rel['type'] == 'BelongsTo' || rel['type'] == 'Join') {
        final fkSqlName = rel['foreignKey'] as String;
        bool mapped = false;
        for (final field in fields) {
          final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
          if (sqlName == fkSqlName) {
            mapped = true;
            break;
          }
        }
        if (!mapped) {
          final sqlType = rel['idType'] as String? ?? 'TEXT';
          columnSql.add('  $fkSqlName $sqlType');
          columnNames.add(fkSqlName);
        }

        final refTable = rel['model'] as String;
        final refColumn = rel['localKey'] as String;
        final onDelete = rel['onDelete'] as String?;
        final onUpdate = rel['onUpdate'] as String?;

        final fk =
            StringBuffer()..write(
              '  FOREIGN KEY($fkSqlName) REFERENCES $refTable($refColumn)',
            );
        if (onDelete != null) fk.write(' ON DELETE $onDelete');
        if (onUpdate != null) fk.write(' ON UPDATE $onUpdate');

        foreignKeys.add(fk.toString());
      }
    }

    // Auto-index foreign key columns of BelongsTo/Join relationships:
    // without an index, loading a parent with its children scans the child
    // table once per parent row. Opt out with @Schema(indexForeignKeys: false).
    final indexForeignKeys =
        schemaReader.peek('indexForeignKeys')?.boolValue ?? true;
    if (indexForeignKeys) {
      final indexedColumns = <String>{};
      for (final rel in relationships) {
        if (rel['type'] != 'BelongsTo' && rel['type'] != 'Join') continue;
        final fkSqlName = rel['foreignKey'] as String;
        if (!indexedColumns.add(fkSqlName)) continue;
        final stmt =
            'CREATE INDEX IF NOT EXISTS ${tableName}_${fkSqlName}_idx '
            'ON $tableName($fkSqlName);';
        indexSql = indexSql.isEmpty ? stmt : '$indexSql\n$stmt';
      }
    }

    // Emit CREATE TABLE statements for pivot tables of ManyToMany relations
    // that opted in via `createPivot: true`. Appended to the schema string so
    // they are created alongside the model table (and re-run through migrations).
    final pivotSql = _generatePivotTables(
      relationships,
      primaryKeySqlType,
      tableName,
      primaryKey,
      indexForeignKeys: indexForeignKeys,
    );
    if (pivotSql.isNotEmpty) {
      indexSql = indexSql.isEmpty ? pivotSql : '$indexSql\n$pivotSql';
    }

    return stringSchemaBuilder(
      columns: columnSql,
      foreignKeys: foreignKeys,
      className: className,
      tableName: tableName,
      fileName: fileName,
      columnNames: columnNames,
      primaryKey: primaryKey,
      indexSql: indexSql,
      relationships: relationships,
      timestamps: timestamps,
      useFromJson: useFromJson,
      isGeneric: element.typeParameters.isNotEmpty,
    );
  }

  List<Map<String, dynamic>> _extractRelationships(
    ConstantReader reader,
    SchemaGenerator dialect,
  ) {
    final list = reader.peek('relationships');
    if (list == null || list.isNull) return [];

    return list.listValue.map((item) {
      final r = ConstantReader(item);
      final type = item.type!.element!.name;
      final modelReader = r.read('model');
      final res = <String, dynamic>{
        'type': type,
        'model': _resolveModelName(modelReader),
        'idType': MetadataExtractor.resolveIdSqlType(modelReader, dialect),
        'foreignKey': r.read('foreignKey').stringValue,
        'localKey': r.read('localKey').stringValue,
        'onDelete': r.peek('onDelete')?.stringValue,
        'onUpdate': r.peek('onUpdate')?.stringValue,
      };

      if (type == 'ManyToMany') {
        res['pivotTable'] = r.read('pivotTable').stringValue;
        res['relatedKey'] = r.read('relatedKey').stringValue;
        res['relatedLocalKey'] = r.read('relatedLocalKey').stringValue;
        res['createPivot'] = r.peek('createPivot')?.boolValue ?? false;
        res['pivotForeignKeys'] =
            r.peek('pivotForeignKeys')?.boolValue ?? false;
      }
      return res;
    }).toList();
  }

  Map<String, dynamic> _parseRelationship(
    ElementAnnotation meta,
    SchemaGenerator dialect,
  ) {
    final reader = ConstantReader(meta.computeConstantValue());
    final type = meta.element!.enclosingElement!.name!;
    final modelReader = reader.read('model');
    final res = <String, dynamic>{
      'type': type,
      'model': _resolveModelName(modelReader),
      'idType': MetadataExtractor.resolveIdSqlType(modelReader, dialect),
      'foreignKey': reader.read('foreignKey').stringValue,
      'localKey': reader.read('localKey').stringValue,
      'onDelete': reader.peek('onDelete')?.stringValue,
      'onUpdate': reader.peek('onUpdate')?.stringValue,
    };

    // Field-level relationships are only scanned for BelongsTo/HasMany/HasOne/
    // Join (see the caller), so `type` is never 'ManyToMany' here. Kept for
    // symmetry with class-level parsing; excluded from coverage.
    // coverage:ignore-start
    if (type == 'ManyToMany') {
      res['pivotTable'] = reader.read('pivotTable').stringValue;
      res['relatedKey'] = reader.read('relatedKey').stringValue;
      res['relatedLocalKey'] = reader.read('relatedLocalKey').stringValue;
      res['createPivot'] = reader.peek('createPivot')?.boolValue ?? false;
      res['pivotForeignKeys'] =
          reader.peek('pivotForeignKeys')?.boolValue ?? false;
    }
    // coverage:ignore-end
    return res;
  }

  String _resolveModelName(ConstantReader modelReader) {
    if (modelReader.isString) {
      return modelReader.stringValue;
    }

    try {
      final type = modelReader.typeValue;
      final element = type.element;
      if (element is ClassElement) {
        // Try to find @Schema annotation on the class
        final schemaMeta =
            element.metadata.annotations
                .where((m) => m.element?.enclosingElement?.name == 'Schema')
                .firstOrNull;

        if (schemaMeta != null) {
          final schemaReader = ConstantReader(
            schemaMeta.computeConstantValue(),
          );
          final tableName = schemaReader.peek('tableName')?.stringValue;
          if (tableName != null) return tableName;
        }

        // Fallback to class name (usually tables are snake_case of class name)
        return element.name ?? '';
      }
    } on Object catch (_) {
      // Not a type or could not resolve
    }

    throw InvalidGenerationSourceError(
      'Relationship model must be a String (table name) or a Model class Type.',
      element: modelReader.objectValue.type?.element,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Pivot tables
  // ──────────────────────────────────────────────────────────────

  /// Builds `CREATE TABLE IF NOT EXISTS` statements for every ManyToMany
  /// relationship that opted in with `createPivot: true`.
  ///
  /// The generated pivot table contains the two foreign-key columns and a
  /// composite primary key over both. [ownerPkSqlType] is the SQL type of the
  /// owning model's primary key (used for the [ManyToMany.foreignKey] column);
  /// the related side uses the resolved `idType` of the related model.
  ///
  /// When a relationship sets `pivotForeignKeys: true`, `FOREIGN KEY (...)
  /// REFERENCES ... ON DELETE CASCADE` constraints are emitted for both columns:
  /// [ManyToMany.foreignKey] references [ownerTable]([ownerPrimaryKey]) and
  /// [ManyToMany.relatedKey] references the related model's table/local key.
  String _generatePivotTables(
    List<Map<String, dynamic>> relationships,
    String ownerPkSqlType,
    String ownerTable,
    String ownerPrimaryKey, {
    required bool indexForeignKeys,
  }) {
    final buffer = StringBuffer();
    final seen = <String>{};

    for (final rel in relationships) {
      if (rel['type'] != 'ManyToMany') continue;
      if (rel['createPivot'] != true) continue;

      final pivotTable = rel['pivotTable'] as String;
      if (!seen.add(pivotTable)) continue; // de-dupe identical pivot tables

      final foreignKey = rel['foreignKey'] as String;
      final relatedKey = rel['relatedKey'] as String;
      final relatedType = rel['idType'] as String? ?? 'TEXT';
      final withForeignKeys = rel['pivotForeignKeys'] == true;

      buffer
        ..writeln('CREATE TABLE IF NOT EXISTS $pivotTable (')
        ..writeln('  $foreignKey $ownerPkSqlType NOT NULL,')
        ..writeln('  $relatedKey $relatedType NOT NULL,');

      if (withForeignKeys) {
        final ownerLocalKey = rel['localKey'] as String? ?? ownerPrimaryKey;
        final relatedTable = rel['model'] as String;
        final relatedLocalKey = rel['relatedLocalKey'] as String? ?? 'id';

        buffer
          ..writeln('  PRIMARY KEY ($foreignKey, $relatedKey),')
          ..writeln(
            '  FOREIGN KEY ($foreignKey) REFERENCES $ownerTable($ownerLocalKey) ON DELETE CASCADE,',
          )
          ..writeln(
            '  FOREIGN KEY ($relatedKey) REFERENCES $relatedTable($relatedLocalKey) ON DELETE CASCADE',
          );
      } else {
        buffer.writeln('  PRIMARY KEY ($foreignKey, $relatedKey)');
      }

      buffer.writeln(');');

      if (indexForeignKeys) {
        // The composite PRIMARY KEY (foreignKey, relatedKey) already serves
        // as an index for foreignKey lookups; relatedKey needs its own.
        buffer.writeln(
          'CREATE INDEX IF NOT EXISTS ${pivotTable}_${relatedKey}_idx '
          'ON $pivotTable($relatedKey);',
        );
      }
    }

    return buffer.toString().trim();
  }

  // ──────────────────────────────────────────────────────────────
  // Indexes
  // ──────────────────────────────────────────────────────────────

  String _generateIndexes(ConstantReader schema, String tableName) {
    final indexes = schema.peek('indexes');
    if (indexes == null || indexes.isNull) return '';

    final buffer = StringBuffer();

    for (final index in indexes.listValue) {
      final reader = ConstantReader(index);
      final columns = reader
          .read('columns')
          .listValue
          .map((c) => c.toStringValue())
          .join(', ');
      final unique = reader.peek('unique')?.boolValue ?? false;

      final indexName = '${tableName}_${columns.replaceAll(', ', '_')}_idx';

      buffer.writeln(
        'CREATE ${unique ? 'UNIQUE ' : ''}INDEX $indexName ON $tableName($columns);',
      );
    }

    return buffer.toString().trim();
  }

  // ─────────────────────────────────────────────────────────────
  // Column generation
  // ─────────────────────────────────────────────────────────────

  _ColumnResult _generateColumn(
    FieldElement field,
    ElementAnnotation meta,
    ColumnNamingStrategy strategy,
    SchemaGenerator dialect,
  ) {
    final reader = ConstantReader(meta.computeConstantValue());
    final annotationName = meta.element!.enclosingElement!.name;

    final explicitName = reader.peek('columnName')?.stringValue;

    String columnName;

    final fieldName = field.name ?? '';
    if (explicitName != null) {
      columnName = explicitName;
    } else {
      switch (strategy) {
        case ColumnNamingStrategy.snakeCase:
          columnName = _camelToSnake(fieldName);
        case ColumnNamingStrategy.pascalCase:
          columnName = fieldName[0].toUpperCase() + fieldName.substring(1);
        default:
          columnName = fieldName;
      }
    }

    final nullable =
        reader.peek('nullable')?.boolValue ??
        field.type.nullabilitySuffix == NullabilitySuffix.question;

    final unique = reader.peek('unique')?.boolValue ?? false;
    final defaultValue = reader.peek('defaultValue');

    final sqlType = MetadataExtractor.resolveSqlType(field, dialect);
    final collation = MetadataExtractor.resolveCollation(field);

    final buffer = StringBuffer()..write('  $columnName $sqlType');

    if (collation != null) {
      buffer.write(' COLLATE $collation');
    }

    final isId = annotationName == 'ID';
    final isAutoPk = dialect.isAutoPkInline(sqlType);

    if (isId) {
      buffer.write(' PRIMARY KEY');
      if (reader.peek('autoIncrement')?.boolValue ?? false) {
        buffer.write(dialect.autoIncrementClause());
      }
    }

    final skipConstraints = isId && isAutoPk;

    if (!nullable && !skipConstraints) buffer.write(' NOT NULL');
    if (unique && !skipConstraints) buffer.write(' UNIQUE');

    if (defaultValue != null && !defaultValue.isNull) {
      buffer.write(' DEFAULT ${_formatDefaultValue(defaultValue, dialect)}');
    }

    final validatorsReader = reader.peek('validators');
    if (validatorsReader != null &&
        !validatorsReader.isNull &&
        validatorsReader.isList) {
      // Anonymous ISqlValidator expressions to be combined into one CHECK(...)
      final anonymousSqls = <String>[];

      for (final validatorObj in validatorsReader.listValue) {
        final validatorReader = ConstantReader(validatorObj);

        if (!const TypeChecker.typeNamed(
          ISqlValidator,
        ).isAssignableFromType(validatorObj.type!)) {
          // Not an ISqlValidator — skip (IJsonValidator only, no SQL needed)
          continue;
        }

        final sql = _getCheckSql(validatorReader, columnName);
        if (sql == null || sql.isEmpty) continue;

        final constraintName = validatorReader.peek('constraint')?.stringValue;

        if (constraintName != null) {
          // Named validator: emit its own CONSTRAINT name CHECK(...) immediately
          buffer.write(' CONSTRAINT $constraintName CHECK($sql)');
        } else {
          // Anonymous validator: accumulate to merge later
          anonymousSqls.add(sql);
        }
      }

      // Combine remaining anonymous checks into one CHECK(expr AND expr ...)
      if (anonymousSqls.isNotEmpty) {
        final combined =
            anonymousSqls.length > 1
                ? anonymousSqls.map((c) => '($c)').join(' AND ')
                : anonymousSqls.first;
        buffer.write(' CHECK($combined)');
      }
    }

    return _ColumnResult(columnName: columnName, columnSql: buffer.toString());
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  String _formatDefaultValue(ConstantReader value, SchemaGenerator dialect) {
    if (value.isBool) return dialect.formatBoolDefault(value.boolValue);
    if (value.isInt) return value.intValue.toString();
    if (value.isDouble) return value.doubleValue.toString();
    if (value.isString) return "'${value.stringValue}'";
    return 'NULL';
  }

  String _camelToSnake(String input) {
    return input
        .replaceAllMapped(
          RegExp('([a-z])([A-Z])'),
          (m) => '${m[1]}_${m[2]!.toLowerCase()}',
        )
        .toLowerCase();
  }

  /// Resolves the CHECK SQL expression from any [ISqlValidator].
  ///
  /// **Primary path**: reads the `sql` field directly via [ConstantReader].
  /// This works when implementors declare `sql` as a `final String sql` field
  /// (or a trivially constant getter). Complex computed getters cannot be read
  /// at generation time and fall through to the fallback.
  ///
  /// **Fallback path**: if `sql` is unreadable, the method looks for a `values`
  /// field (a `List`) and generates an `IN (...)` clause from its elements.
  /// This transparently handles validators like `ContainsValidator`.
  String? _getCheckSql(ConstantReader reader, String columnName) {
    if (reader.isNull) return null;

    final type = reader.objectValue.type;
    if (type == null) return null;

    // Only process ISqlValidator implementors
    if (!const TypeChecker.typeNamed(
      ISqlValidator,
    ).isAssignableFromType(type)) {
      return null;
    }

    // ── Primary: read the `sql` final-field directly ──────────────────────
    // Works for: `final String sql` fields and simple constant getters.
    // Does NOT work for computed getters (if/else, method calls, etc.).
    final sqlField = reader.peek('sql');
    if (sqlField != null && !sqlField.isNull && sqlField.isString) {
      final sql = sqlField.stringValue;
      if (sql.isNotEmpty) return sql.replaceAll('{column}', columnName);
    }

    // ── Fallback: reconstruct IN clause from a `values` list field ────────
    // Handles validators like ContainsValidator whose sql is computed at
    // runtime from a list of allowed values that cannot be const-inlined.
    final valuesObj = reader.objectValue.getField('values');
    if (valuesObj != null && !valuesObj.isNull) {
      final list = valuesObj.toListValue();
      if (list != null && list.isNotEmpty) {
        final formatted = list
            .map((v) {
              final s = v.toStringValue();
              if (s != null) return "'$s'";
              final i = v.toIntValue();
              if (i != null) return i.toString();
              final d = v.toDoubleValue();
              if (d != null) return d.toString();
              return 'NULL';
            })
            .join(', ');
        return '$columnName IN ($formatted)';
      }
    }

    return null;
  }
}

class _ColumnResult {
  final String columnName;
  final String columnSql;

  _ColumnResult({required this.columnName, required this.columnSql});
}
