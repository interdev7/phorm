import 'dart:async';

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'metadata_extractor.dart';
import 'string_schema_builder.dart';

const _checkInListChecker = TypeChecker.fromRuntime(ContainsValidator);
const _checkRangeChecker = TypeChecker.fromRuntime(RangeValidator);
const _checkComparisonChecker = TypeChecker.fromRuntime(ComparisonValidator);
const _checkLengthChecker = TypeChecker.fromRuntime(LengthValidator);
const _checkNotChecker = TypeChecker.fromRuntime(NotContainsValidator);
const _customSqlChecker = TypeChecker.fromRuntime(CustomSqlValidator);

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
      final checkSqls = <String>[];
      String? lastConstraintName;

      for (final validatorObj in validatorsReader.listValue) {
        final validatorReader = ConstantReader(validatorObj);

        if (const TypeChecker.fromRuntime(ICheckValidator)
            .isAssignableFromType(validatorObj.type!)) {
          final sql = _getCheckSql(validatorReader, columnName);
          if (sql != null && sql.isNotEmpty) {
            checkSqls.add(sql);
            final constraint = validatorReader.peek('constraint')?.stringValue;
            if (constraint != null) lastConstraintName = constraint;
          }
        }
      }

      if (checkSqls.isNotEmpty) {
        final combinedSql = checkSqls.length > 1
            ? checkSqls.map((c) => '($c)').join('AND')
            : checkSqls.first;

        if (lastConstraintName != null) {
          buffer.write(' CONSTRAINT $lastConstraintName CHECK($combinedSql)');
        } else {
          buffer.write(' CHECK($combinedSql)');
        }
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

  String? _getCheckSql(ConstantReader reader, String columnName) {
    if (reader.isNull) return null;

    if (_checkInListChecker.isExactlyType(reader.objectValue.type!)) {
      final values = reader.read('values').listValue.map((v) {
        final r = ConstantReader(v);
        if (r.isString) return "'${r.stringValue}'";
        return r.objectValue.toString();
      }).join(', ');
      return '$columnName IN ($values)';
    }

    if (_checkRangeChecker.isExactlyType(reader.objectValue.type!)) {
      final min = _readNum(reader.read('min'));
      final max = _readNum(reader.read('max'));
      if (min != null && max != null) {
        return '$columnName BETWEEN $min AND $max';
      }
      if (min != null) return '$columnName >= $min';
      if (max != null) return '$columnName <= $max';
      return null;
    }

    if (_checkComparisonChecker.isExactlyType(reader.objectValue.type!)) {
      final value = _readNum(reader.read('value'));
      final operator = reader.read('operator').stringValue;
      return '$columnName $operator $value';
    }

    if (_checkLengthChecker.isExactlyType(reader.objectValue.type!)) {
      final min = reader.peek('min')?.intValue;
      final max = reader.peek('max')?.intValue;
      final lengthExpr = 'LENGTH($columnName)';
      if (min != null && max != null) {
        return '$lengthExpr BETWEEN $min AND $max';
      }
      if (min != null) return '$lengthExpr >= $min';
      if (max != null) return '$lengthExpr <= $max';
      return null;
    }

    if (_checkNotChecker.isExactlyType(reader.objectValue.type!)) {
      final condition = reader.read('condition');
      final innerSql = _getCheckSql(condition, columnName);
      return innerSql != null ? 'NOT ($innerSql)' : null;
    }

    if (_customSqlChecker.isExactlyType(reader.objectValue.type!)) {
      final sql = reader.read('sql').stringValue;
      return sql.replaceAll('{column}', columnName);
    }

    return null;
  }

  num? _readNum(ConstantReader reader) {
    if (reader.isNull) return null;
    if (reader.isInt) return reader.intValue;
    if (reader.isDouble) return reader.doubleValue;
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
