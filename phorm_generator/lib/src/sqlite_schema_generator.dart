import 'dart:async';

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'metadata_extractor.dart';
import 'string_schema_builder.dart';

// Generator works with any ISqlValidator via its `sql` field.
// No concrete checker classes needed — users define their own validators.

class SqliteSchemaGenerator extends GeneratorForAnnotation<Schema> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader schemaReader,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Only classes can be annotated with @Schema',
        element: element,
      );
    }

    final className = element.name;
    final tableName =
        schemaReader.peek('tableName')?.stringValue ?? _camelToSnake(className);
    final useFromJson = schemaReader.peek('useFromJson')?.boolValue ?? true;

    final strategyReader = schemaReader.peek('columnNaming');
    final strategy = strategyReader == null || strategyReader.isNull
        ? ColumnNamingStrategy.snakeCase
        : ColumnNamingStrategy.values.firstWhere(
            (e) => e.name == strategyReader.revive().accessor.split('.').last,
            orElse: () => throw InvalidGenerationSourceError(
              'Unknown ColumnNamingStrategy value',
              element: element,
            ),
          );

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

    for (final field in fields) {
      final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
      if (sqlName == 'created_at') hasCreatedAt = true;
      if (sqlName == 'updated_at') hasUpdatedAt = true;
      if (sqlName == 'deleted_at') hasDeletedAt = true;

      final annotationMeta = field.metadata.where((m) {
        final name = m.element?.enclosingElement3?.name;
        return name == 'Column' || name == 'ID';
      }).firstOrNull;

      if (annotationMeta != null &&
          annotationMeta.element?.enclosingElement3?.name == 'ID') {
        primaryKey = sqlName;
      }

      if (annotationMeta == null) continue;

      final result = _generateColumn(field, annotationMeta, strategy);
      columnSql.add(result.columnSql);
      columnNames.add(result.columnName);
    }

    if (timestamps) {
      if (!hasCreatedAt) {
        columnSql.add('  created_at TEXT NOT NULL');
        columnNames.add('created_at');
      }
      if (!hasUpdatedAt) {
        columnSql.add('  updated_at TEXT NOT NULL');
        columnNames.add('updated_at');
      }
    }

    if (paranoid && !hasDeletedAt) {
      columnSql.add('  deleted_at TEXT');
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
      final triggerSql = _generateTrigger(tableName);
      if (indexSql.isNotEmpty) {
        indexSql += '\n$triggerSql';
      } else {
        indexSql = triggerSql;
      }
    }

    final List<Map<String, dynamic>> relationships = [
      ..._extractRelationships(schemaReader)
    ];

    // Also scan fields for @BelongsTo, @HasMany, @HasOne, @Join
    for (final field in fields) {
      final fieldMeta = field.metadata.where((m) {
        final name = m.element?.enclosingElement3?.name;
        return name == 'BelongsTo' ||
            name == 'HasMany' ||
            name == 'HasOne' ||
            name == 'Join';
      }).firstOrNull;

      if (fieldMeta != null) {
        relationships.add(_parseRelationship(fieldMeta));
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

        final fk = StringBuffer()
          ..write('  FOREIGN KEY($fkSqlName) REFERENCES $refTable($refColumn)');
        if (onDelete != null) fk.write(' ON DELETE $onDelete');
        if (onUpdate != null) fk.write(' ON UPDATE $onUpdate');

        foreignKeys.add(fk.toString());
      }
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

  List<Map<String, dynamic>> _extractRelationships(ConstantReader reader) {
    final list = reader.peek('relationships');
    if (list == null || list.isNull) return [];

    return list.listValue.map((item) {
      final r = ConstantReader(item);
      final type = item.type!.element!.name;
      final modelReader = r.read('model');
      final res = {
        'type': type,
        'model': _resolveModelName(modelReader),
        'idType': MetadataExtractor.resolveIdSqlType(modelReader),
        'foreignKey': r.read('foreignKey').stringValue,
        'localKey': r.read('localKey').stringValue,
        'onDelete': r.peek('onDelete')?.stringValue,
        'onUpdate': r.peek('onUpdate')?.stringValue,
      };

      if (type == 'ManyToMany') {
        res['pivotTable'] = r.read('pivotTable').stringValue;
        res['relatedKey'] = r.read('relatedKey').stringValue;
        res['relatedLocalKey'] = r.read('relatedLocalKey').stringValue;
      }
      return res;
    }).toList();
  }

  Map<String, dynamic> _parseRelationship(ElementAnnotation meta) {
    final reader = ConstantReader(meta.computeConstantValue());
    final type = meta.element!.enclosingElement3!.name!;
    final modelReader = reader.read('model');
    final res = {
      'type': type,
      'model': _resolveModelName(modelReader),
      'idType': MetadataExtractor.resolveIdSqlType(modelReader),
      'foreignKey': reader.read('foreignKey').stringValue,
      'localKey': reader.read('localKey').stringValue,
      'onDelete': reader.peek('onDelete')?.stringValue,
      'onUpdate': reader.peek('onUpdate')?.stringValue,
    };

    if (type == 'ManyToMany') {
      res['pivotTable'] = reader.read('pivotTable').stringValue;
      res['relatedKey'] = reader.read('relatedKey').stringValue;
      res['relatedLocalKey'] = reader.read('relatedLocalKey').stringValue;
    }
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
        final schemaMeta = element.metadata
            .where((m) => m.element?.enclosingElement3?.name == 'Schema')
            .firstOrNull;

        if (schemaMeta != null) {
          final schemaReader =
              ConstantReader(schemaMeta.computeConstantValue());
          final tableName = schemaReader.peek('tableName')?.stringValue;
          if (tableName != null) return tableName;
        }

        // Fallback to class name (usually tables are snake_case of class name)
        return element.name;
      }
    } catch (_) {
      // Not a type or could not resolve
    }

    throw InvalidGenerationSourceError(
      'Relationship model must be a String (table name) or a Model class Type.',
      element: modelReader.objectValue.type?.element,
    );
  }

  // Generate TRigger
  // CREATE TRIGGER update_posts_timestamp
  // AFTER UPDATE ON posts
  // FOR EACH ROW
  // BEGIN
  //     UPDATE posts SET updated_at = datetime('now') WHERE id = OLD.id;
  // END;
  // НУжно чтобы красиво выглядело и структурированно
  String _generateTrigger(String tableName) {
    return '''

CREATE TRIGGER update_${tableName}_timestamp
AFTER UPDATE ON $tableName
FOR EACH ROW
BEGIN
    UPDATE $tableName SET updated_at = datetime('now') WHERE id = OLD.id;
END;''';
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
  ) {
    final reader = ConstantReader(meta.computeConstantValue());
    final annotationName = meta.element!.enclosingElement3!.name;

    final explicitName = reader.peek('columnName')?.stringValue;

    String columnName;

    if (explicitName != null) {
      columnName = explicitName;
    } else {
      switch (strategy) {
        case ColumnNamingStrategy.snakeCase:
          columnName = _camelToSnake(field.name);
        case ColumnNamingStrategy.pascalCase:
          columnName = field.name[0].toUpperCase() + field.name.substring(1);
        default:
          columnName = field.name;
      }
    }

    final nullable = reader.peek('nullable')?.boolValue ??
        field.type.nullabilitySuffix == NullabilitySuffix.question;

    final unique = reader.peek('unique')?.boolValue ?? false;
    final defaultValue = reader.peek('defaultValue');

    final sqlType = MetadataExtractor.resolveSqlType(field);
    final collation = MetadataExtractor.resolveCollation(field);

    final buffer = StringBuffer()..write('  $columnName $sqlType');

    if (collation != null) {
      buffer.write(' COLLATE $collation');
    }

    final isId = annotationName == 'ID';
    final isInteger = sqlType == 'INTEGER';

    if (isId) {
      buffer.write(' PRIMARY KEY');
      if (reader.peek('autoIncrement')?.boolValue ?? false) {
        buffer.write(' AUTOINCREMENT');
      }
    }

    final skipConstraints = isId && isInteger;

    if (!nullable && !skipConstraints) buffer.write(' NOT NULL');
    if (unique && !skipConstraints) buffer.write(' UNIQUE');

    if (defaultValue != null && !defaultValue.isNull) {
      buffer.write(' DEFAULT ${_formatDefaultValue(defaultValue)}');
    }

    final validatorsReader = reader.peek('validators');
    if (validatorsReader != null &&
        !validatorsReader.isNull &&
        validatorsReader.isList) {
      // Anonymous ISqlValidator expressions to be combined into one CHECK(...)
      final anonymousSqls = <String>[];

      for (final validatorObj in validatorsReader.listValue) {
        final validatorReader = ConstantReader(validatorObj);

        if (!const TypeChecker.fromRuntime(ISqlValidator)
            .isAssignableFromType(validatorObj.type!)) {
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
        final combined = anonymousSqls.length > 1
            ? anonymousSqls.map((c) => '($c)').join(' AND ')
            : anonymousSqls.first;
        buffer.write(' CHECK($combined)');
      }
    }

    return _ColumnResult(
      columnName: columnName,
      columnSql: buffer.toString(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  String _formatDefaultValue(ConstantReader value) {
    if (value.isBool) return value.boolValue ? '1' : '0';
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
    if (!const TypeChecker.fromRuntime(ISqlValidator)
        .isAssignableFromType(type)) {
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
        final formatted = list.map((v) {
          final s = v.toStringValue();
          if (s != null) return "'$s'";
          final i = v.toIntValue();
          if (i != null) return i.toString();
          final d = v.toDoubleValue();
          if (d != null) return d.toString();
          return 'NULL';
        }).join(', ');
        return '$columnName IN ($formatted)';
      }
    }

    return null;
  }


}

class _ColumnResult {
  final String columnName;
  final String columnSql;

  _ColumnResult({
    required this.columnName,
    required this.columnSql,
  });
}
