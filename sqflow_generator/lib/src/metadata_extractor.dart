import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

class ConverterInfo {
  final String code;
  final DartType sqlType;

  ConverterInfo(this.code, this.sqlType);
}

class MetadataExtractor {
  static const columnChecker = TypeChecker.fromUrl(
      'package:sqflow_platform_interface/src/annotations.dart#Column');
  static const idChecker = TypeChecker.fromUrl(
      'package:sqflow_platform_interface/src/annotations.dart#ID');
  static const foreignKeyChecker = TypeChecker.fromUrl(
      'package:sqflow_platform_interface/src/annotations.dart#ForeignKey');
  static const belongsToChecker = TypeChecker.fromUrl(
      'package:sqflow_platform_interface/src/annotations.dart#BelongsTo');
  static const valueConverterChecker = TypeChecker.fromUrl(
      'package:sqflow_platform_interface/src/value_converter.dart#ValueConverter');

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
        
        return resolveSqlType(idField);
      }
    } catch (_) {}
    return null;
  }

  static String resolveSqlType(FieldElement field) {
    final annotation = columnChecker.firstAnnotationOf(field) ?? 
                       idChecker.firstAnnotationOf(field);

    if (annotation != null) {
      final reader = ConstantReader(annotation);
      
      // 1. If explicit sqlType is provided, it takes priority
      final explicitType = reader.peek('sqlType')?.stringValue;
      if (explicitType != null) return explicitType;

      // 2. Check if there's a converter
      final info = getConverterInfo(field);
      if (info != null) {
        final sqlType = info.sqlType;
        if (sqlType.isDartCoreInt) return 'INTEGER';
        if (sqlType.isDartCoreDouble) return 'REAL';
        if (sqlType.isDartCoreBool) return 'INTEGER';
        if (sqlType.isDartCoreString) return 'TEXT';
        if (sqlType.element?.name == 'num') return 'NUMERIC';
        if (sqlType.element?.name == 'Uint8List') return 'BLOB';
      }
    }

    final type = field.type;
    if (type.isDartCoreInt) return 'INTEGER';
    if (type.isDartCoreDouble) return 'REAL';
    if (type.isDartCoreBool) return 'INTEGER';
    if (type.isDartCoreString) return 'TEXT';
    
    final typeName = type.element?.name;
    if (typeName == 'num') return 'NUMERIC';
    if (typeName == 'DateTime') return 'TEXT';
    if (typeName == 'Uint8List') return 'BLOB';
    
    return 'TEXT';
  }

  static ConverterInfo? getConverterInfo(FieldElement field) {
    final annotation = columnChecker.firstAnnotationOf(field) ?? 
                       idChecker.firstAnnotationOf(field);

    if (annotation == null) return null;
    final reader = ConstantReader(annotation);
    final converterReader = reader.peek('converter');
    
    if (converterReader == null || converterReader.isNull) return null;

    final converterType = converterReader.objectValue.type!;
    if (converterType is! InterfaceType) return null;

    // Find ValueConverter in the hierarchy to get type arguments
    final valueConverterType = [converterType, ...converterType.allSupertypes].firstWhere(
      (t) => valueConverterChecker.isExactly(t.element),
      orElse: () => throw 'Converter ${converterType.element.name} must inherit from ValueConverter',
    );

    final typeArguments = valueConverterType.typeArguments;
    if (typeArguments.length < 2) return null;

    final revived = converterReader.revive();
    // Use the class name from the revived object
    final typeName = revived.source.fragment;
    
    return ConverterInfo('const $typeName()', typeArguments[1]);
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
    final annotation = columnChecker.firstAnnotationOf(field) ?? 
                       idChecker.firstAnnotationOf(field);

    if (annotation == null) return camelToSnake(field.name);

    final reader = ConstantReader(annotation);
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
