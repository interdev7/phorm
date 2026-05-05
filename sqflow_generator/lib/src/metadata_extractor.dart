import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

class MetadataExtractor {
  static String resolveModelName(ConstantReader modelReader) {
    if (modelReader.isString) {
      return modelReader.stringValue;
    }

    try {
      final type = modelReader.typeValue;
      final element = type.element;
      if (element is ClassElement) {
        final schemaMeta = element.metadata
            .where((m) => m.element?.enclosingElement3?.name == 'Schema')
            .firstOrNull;

        if (schemaMeta != null) {
          final schemaReader =
              ConstantReader(schemaMeta.computeConstantValue());
          final tableName = schemaReader.peek('tableName')?.stringValue;
          if (tableName != null) return tableName;
        }
        return camelToSnake(element.name);
      }
    } catch (_) {}

    return 'unknown';
  }

  static String resolveModelClass(ConstantReader modelReader) {
    try {
      if (modelReader.isType) {
        final type = modelReader.typeValue;
        return type.element?.name ?? 'dynamic';
      }
      if (modelReader.isString) {
        String name = modelReader.stringValue;
        if (name.endsWith('ies')) {
          name = '${name.substring(0, name.length - 3)}y';
        } else if (name.endsWith('s')) {
          name = name.substring(0, name.length - 1);
        }
        return name
            .split('_')
            .map((e) => e[0].toUpperCase() + e.substring(1))
            .join();
      }
      return 'dynamic';
    } catch (_) {
      return 'dynamic';
    }
  }

  static String? resolveIdSqlType(ConstantReader modelReader) {
    try {
      final type = modelReader.typeValue;
      final element = type.element;
      if (element is ClassElement) {
        final idField = element.fields.firstWhere((f) =>
            f.metadata.any((m) => m.element?.enclosingElement3?.name == 'ID'));
        final idMeta = idField.metadata
            .firstWhere((m) => m.element?.enclosingElement3?.name == 'ID');
        final typeReader =
            ConstantReader(idMeta.computeConstantValue()).read('type');
        final typeName = typeReader.peek('name')?.stringValue ??
            typeReader.objectValue.type?.element?.name ??
            typeReader.revive().accessor.split('.').last;

        if (typeName == 'INTEGER') return 'INTEGER';
        if (typeName == 'REAL') return 'REAL';
        if (typeName == 'BLOB') return 'BLOB';
        if (typeName == 'NUMERIC') return 'NUMERIC';
        return 'TEXT';
      }
    } catch (_) {}
    return null;
  }

  static String camelToSnake(String input) {
    return input
        .replaceAllMapped(
          RegExp('([a-z])([A-Z])'),
          (m) => '${m[1]}_${m[2]!.toLowerCase()}',
        )
        .toLowerCase();
  }

  static String snakeToCamel(String input) {
    return input.split('_').asMap().entries.map((e) {
      if (e.key == 0) return e.value;
      if (e.value.isEmpty) return '';
      return e.value[0].toUpperCase() + e.value.substring(1);
    }).join();
  }

  static String getSqlColumnName(
      FieldElement field, ColumnNamingStrategy strategy) {
    final meta = field.metadata.where((m) {
      final name = m.element?.enclosingElement3?.name;
      return name == 'Column' || name == 'ID';
    }).firstOrNull;

    if (meta == null) return camelToSnake(field.name);

    final reader = ConstantReader(meta.computeConstantValue());
    final explicitName = reader.peek('columnName')?.stringValue;
    if (explicitName != null) return explicitName;

    switch (strategy) {
      case ColumnNamingStrategy.snakeCase:
        return camelToSnake(field.name);
      case ColumnNamingStrategy.pascalCase:
        return field.name[0].toUpperCase() + field.name.substring(1);
      default:
        return field.name;
    }
  }
}
