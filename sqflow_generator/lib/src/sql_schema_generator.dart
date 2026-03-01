import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';
import 'package:sqflow_generator/src/string_schema_builder.dart';

class SqlSchemaGenerator extends GeneratorForAnnotation<Schema> {
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

    final paranoid = schemaReader.peek('paranoid')?.boolValue ?? false;

    final fileName = p.basename(buildStep.inputId.path);

    final fields = element.fields.where((f) => !f.isStatic).toList();

    final columnSql = <String>[];
    final foreignKeys = <String>[];

    bool hasDeletedAt = false;

    for (final field in fields) {
      if (field.name == 'deletedAt') {
        hasDeletedAt = true;
      }

      final annotationMeta = field.metadata.where((m) {
        final name = m.element?.enclosingElement3?.name;
        return name == 'Column' || name == 'ID' || name == 'ForeignKey';
      }).firstOrNull;

      if (annotationMeta == null) continue;

      final result = _generateColumn(field, annotationMeta, strategy);
      columnSql.add(result.columnSql);

      if (result.foreignKeySql != null) {
        foreignKeys.add(result.foreignKeySql!);
      }
    }

    if (paranoid && !hasDeletedAt) {
      throw InvalidGenerationSourceError(
        'Schema is paranoid but no `deletedAt` field found in $className',
        element: element,
      );
    }

    if (columnSql.isEmpty) {
      throw InvalidGenerationSourceError(
        'Class $className has no columns',
        element: element,
      );
    }

    final indexSql = _generateIndexes(schemaReader, tableName);

    return stringSchemaBuilder(
      columns: columnSql,
      foreignKeys: foreignKeys,
      className: className,
      tableName: tableName,
      fileName: fileName,
      indexSql: indexSql,
    );
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

    final explicitName = reader.peek('name')?.stringValue;

    String columnName;

    if (explicitName != null) {
      columnName = explicitName;
    } else {
      // Нет явного имени → применяем стратегию
      switch (strategy) {
        case ColumnNamingStrategy.snakeCase:
          columnName = _camelToSnake(field.name);
          break;
        case ColumnNamingStrategy.pascalCase:
          columnName = field.name[0].toUpperCase() + field.name.substring(1);
          break;
        default:
          columnName = field.name;
          break;
      }
    }

    final typeEnum = reader.read('type').revive();
    final typeName = typeEnum.accessor.split('.').last;

    final nullable = reader.peek('nullable')?.boolValue ??
        field.type.nullabilitySuffix == NullabilitySuffix.question;

    final unique = reader.peek('unique')?.boolValue ?? false;
    final defaultValue = reader.peek('defaultValue');
    final check = reader.peek('check');

    final length = reader.peek('length')?.intValue;
    final precision = reader.peek('precision')?.intValue;
    final scale = reader.peek('scale')?.intValue;

    final buffer = StringBuffer();
    buffer.write(
        '  $columnName ${_mapDataType(typeName, length, precision, scale)}');

    if (annotationName == 'ID') {
      buffer.write(' PRIMARY KEY');
      if (reader.peek('autoIncrement')?.boolValue ?? false) {
        buffer.write(' AUTOINCREMENT');
      }
    }

    if (!nullable) buffer.write(' NOT NULL');
    if (unique) buffer.write(' UNIQUE');

    if (defaultValue != null && !defaultValue.isNull) {
      buffer.write(' DEFAULT ${_formatDefaultValue(defaultValue)}');
    }

    if (check != null && !check.isNull) {
      final values = check.read('values').listValue.map((v) {
        if (v.toTypeValue() != null) return v.toTypeValue().toString();
        if (v.toBoolValue() != null) return v.toBoolValue()! ? '1' : '0';
        if (v.toIntValue() != null) return v.toIntValue().toString();
        if (v.toDoubleValue() != null) return v.toDoubleValue().toString();
        if (v.toStringValue() != null) return "'${v.toStringValue()}'";
        return v.toString();
      }).join(', ');
      buffer.write(' CHECK($columnName IN ($values))');
    }

    String? foreignKeySql;

    if (annotationName == 'ForeignKey') {
      final refTable = reader.read('referencesTable').stringValue;
      final refColumn = reader.read('referencesColumn').stringValue;
      final onDelete = reader.peek('onDelete')?.stringValue;
      final onUpdate = reader.peek('onUpdate')?.stringValue;

      final fk = StringBuffer();
      fk.write('  FOREIGN KEY($columnName) REFERENCES $refTable($refColumn)');
      if (onDelete != null) fk.write(' ON DELETE $onDelete');
      if (onUpdate != null) fk.write(' ON UPDATE $onUpdate');

      foreignKeySql = fk.toString();
    }

    return _ColumnResult(
      columnSql: buffer.toString(),
      foreignKeySql: foreignKeySql,
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

  String _mapDataType(
    String type,
    int? length,
    int? precision,
    int? scale,
  ) {
    switch (type) {
      case 'INTEGER':
      case 'BIGINT':
        return 'INTEGER';
      case 'REAL':
        return 'REAL';
      case 'TEXT':
      case 'JSON':
        return 'TEXT';
      case 'VARCHAR':
        return length != null ? 'VARCHAR($length)' : 'TEXT';
      case 'CHAR':
        return length != null ? 'CHAR($length)' : 'CHAR(1)';
      case 'DECIMAL':
        if (precision != null && scale != null) {
          return 'DECIMAL($precision,$scale)';
        } else if (precision != null) {
          return 'DECIMAL($precision)';
        }
        return 'DECIMAL';
      case 'BOOLEAN':
        return 'INTEGER';
      case 'DATE':
      case 'DATETIME':
      case 'TIME':
        return 'TEXT';
      case 'BLOB':
        return 'BLOB';
      default:
        return 'TEXT';
    }
  }

  String _camelToSnake(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]}_${m[2]!.toLowerCase()}',
        )
        .toLowerCase();
  }
}

// ─────────────────────────────────────────────────────────────
// Internal helper
// ─────────────────────────────────────────────────────────────

class _ColumnResult {
  final String columnSql;
  final String? foreignKeySql;

  _ColumnResult({
    required this.columnSql,
    this.foreignKeySql,
  });
}
