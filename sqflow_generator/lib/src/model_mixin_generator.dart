import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sqflow_platform_interface/src/annotations.dart';

import 'metadata_extractor.dart';

class ModelMixinGenerator extends GeneratorForAnnotation<Schema> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';

    final className = element.name;
    final strategyReader = annotation.peek('columnNaming');
    final strategy = strategyReader == null || strategyReader.isNull
        ? ColumnNamingStrategy.snakeCase
        : ColumnNamingStrategy.values.firstWhere(
            (e) => e.name == strategyReader.revive().accessor.split('.').last,
            orElse: () => ColumnNamingStrategy.snakeCase,
          );
    final useToJson = annotation.peek('useToJson')?.boolValue ?? true;
    final useFromJson = annotation.peek('useFromJson')?.boolValue ?? true;
    final timestamps = annotation.peek('timestamps')?.boolValue ?? true;
    final paranoid = annotation.peek('paranoid')?.boolValue ?? false;

    final fields = element.fields.where((f) => !f.isStatic).toList();
    final relationships = <Map<String, dynamic>>[];

    // Class level relationships
    final relsReader = annotation.peek('relationships');
    if (relsReader != null && !relsReader.isNull) {
      for (final item in relsReader.listValue) {
        final r = ConstantReader(item);
        final type = item.type!.element!.name;
        final modelClass = MetadataExtractor.resolveModelClass(r.read('model'));
        final isCollection = type == 'HasMany';

        var fieldName = MetadataExtractor.camelToSnake(modelClass);
        if (isCollection && !fieldName.endsWith('s')) {
          fieldName = '${fieldName}s';
        }

        final foreignKey = r.read('foreignKey').stringValue;

        relationships.add({
          'type': type,
          'model': MetadataExtractor.resolveModelName(r.read('model')),
          'modelClass': modelClass,
          'isCollection': isCollection,
          'fieldName': fieldName,
          'foreignKey': foreignKey,
          'foreignKeyName': MetadataExtractor.snakeToCamel(foreignKey),
        });
      }
    }

    // Field level relationships
    for (final field in fields) {
      final relMeta = field.metadata.where((m) {
        final name = m.element?.enclosingElement3?.name;
        return name == 'BelongsTo' ||
            name == 'HasMany' ||
            name == 'HasOne' ||
            name == 'Join';
      }).firstOrNull;

      if (relMeta != null) {
        final r = ConstantReader(relMeta.computeConstantValue());
        final type = relMeta.element!.enclosingElement3!.name!;
        var modelClass = MetadataExtractor.resolveModelClass(r.read('model'));
        final fieldTypeStr = field.type.getDisplayString();
        final isCollection = type == 'HasMany';

        if (modelClass == 'dynamic') {
          if (isCollection) {
            final match = RegExp('List<([^>]+)>').firstMatch(fieldTypeStr);
            if (match != null) modelClass = match.group(1)!;
          } else {
            modelClass = fieldTypeStr;
          }
        }

        var fieldName = field.name;

        final fieldType = field.type.getDisplayString();
        if (type == 'BelongsTo' &&
            (fieldType == 'String' ||
                fieldType == 'int' ||
                fieldType == 'dynamic')) {
          fieldName = MetadataExtractor.camelToSnake(modelClass);
        } else if (isCollection && !fieldName.endsWith('s')) {
          fieldName = '${fieldName}s';
        }

        final foreignKey = r.read('foreignKey').stringValue;

        relationships.add({
          'type': type,
          'model': MetadataExtractor.resolveModelName(r.read('model')),
          'modelClass': modelClass,
          'isCollection': isCollection,
          'fieldName': fieldName,
          'foreignKey': foreignKey,
          'foreignKeyName': MetadataExtractor.snakeToCamel(foreignKey),
        });
      }
    }

    final buffer = StringBuffer();

    // 1. Mixin
    buffer.writeln('mixin _\$SQFlow${className}Mixin {');

    // Timestamps fields
    final existsCreatedAt = fields.any((f) => f.name == 'createdAt');
    final existsUpdatedAt = fields.any((f) => f.name == 'updatedAt');
    final existsDeletedAt = fields.any((f) => f.name == 'deletedAt');

    if (timestamps) {
      if (!existsCreatedAt) buffer.writeln('  DateTime? createdAt;');
      if (!existsUpdatedAt) buffer.writeln('  DateTime? updatedAt;');
    }
    if (paranoid && !existsDeletedAt) {
      buffer.writeln('  DateTime? deletedAt;');
    }

    // Relationship fields
    for (final rel in relationships) {
      final modelClass = rel['modelClass'];
      final fieldName = rel['fieldName'];
      final isCollection = rel['isCollection'] as bool;

      final exists = fields.any((f) => f.name == fieldName);
      if (!exists) {
        if (isCollection) {
          buffer
            ..writeln('  final List<$modelClass> _\$$fieldName = [];')
            ..writeln('  List<$modelClass> get $fieldName => _\$$fieldName;');
        } else {
          buffer
            ..writeln('  $modelClass? _\$$fieldName;')
            ..writeln('  $modelClass? get $fieldName => _\$$fieldName;');
        }
      }

      if (rel['type'] == 'BelongsTo') {
        final fkName = rel['foreignKeyName'];
        final existsFk = fields.any((f) => f.name == fkName);
        if (!existsFk) {
          buffer
            ..writeln('  var _\$$fkName;')
            ..writeln('  dynamic get $fkName => $fieldName?.id ?? _\$$fkName;')
            ..writeln('  set $fkName(dynamic value) => _\$$fkName = value;');
        }
      }
    }

    // Close the mixin
    buffer.writeln('}');

    // 2. Extension for toJson
    if (useToJson) {
      buffer
        ..writeln()
        ..writeln('extension _\$SQFlow${className}SqlExt on $className {')
        ..writeln('  Map<String, dynamic> _\$SQFlow${className}ToJson() {')
        ..writeln('    return {');
      for (final field in fields.where((f) => _isColumn(f))) {
        final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
        buffer.writeln("      '$sqlName': _\$SQFlowToJsonValue(${field.name}),");
      }

      if (timestamps) {
        if (!existsCreatedAt) buffer.writeln("      'created_at': _\$SQFlowToJsonValue(createdAt),");
        if (!existsUpdatedAt) buffer.writeln("      'updated_at': _\$SQFlowToJsonValue(updatedAt),");
      }
      if (paranoid && !existsDeletedAt) {
        buffer.writeln("      'deleted_at': _\$SQFlowToJsonValue(deletedAt),");
      }

      // Output synthesized foreign keys in toJson
      for (final rel in relationships) {
        if (rel['type'] == 'BelongsTo') {
          final fkName = rel['foreignKeyName'];
          final fkSqlName = rel['foreignKey'];
          final existsFk = fields.any((f) => f.name == fkName);
          if (!existsFk) {
            buffer.writeln(
                "      '$fkSqlName': _\$SQFlowToJsonValue($fkName),");
          }
        }
      }

      buffer
        ..writeln('    };')
        ..writeln('  }')
        ..writeln('}');
    }

    // 3. fromJson Function
    if (useFromJson) {
      buffer
        ..writeln(
            '\n$className _\$SQFlow${className}FromJson(Map<String, dynamic> json) {')
        ..writeln('  final instance = $className(');

      final constructor =
          element.unnamedConstructor ?? element.constructors.first;
      for (final param in constructor.parameters) {
        final FieldElement? field =
            fields.where((f) => f.name == param.name).firstOrNull;

        final rel =
            relationships.where((r) => r['fieldName'] == param.name).firstOrNull;
        if (rel != null) {
          final modelClass = rel['modelClass'];
          final modelTable = rel['model'];
          if (rel['isCollection'] as bool) {
            buffer.writeln(
                "    ${param.name}: json['$modelTable'] != null ? (json['$modelTable'] as List).map((e) => $modelClass.fromJson(e as Map<String, dynamic>)).toList() : [],");
          } else {
            buffer.writeln(
                "    ${param.name}: json['$modelTable'] != null ? $modelClass.fromJson(json['$modelTable'] as Map<String, dynamic>) : null,");
          }
        } else if (field != null && _isColumn(field)) {
          final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
          final type = param.type.getDisplayString();
          final isNullable =
              param.type.nullabilitySuffix == NullabilitySuffix.question;

          if (type.startsWith('DateTime')) {
            if (isNullable) {
              buffer.writeln(
                  "    ${param.name}: json['$sqlName'] != null ? DateTime.parse(json['$sqlName'] as String) : null,");
            } else {
              buffer.writeln(
                  "    ${param.name}: DateTime.parse(json['$sqlName'] as String),");
            }
          } else if (type == 'bool' || type == 'bool?') {
            // Handle both int (SQLite: 0/1) and bool (in-memory JSON) values
            buffer.writeln(
                "    ${param.name}: json['$sqlName'] is bool ? json['$sqlName'] as bool : (json['$sqlName'] as int?) == 1,");
          } else {
            buffer.writeln("    ${param.name}: json['$sqlName'] as $type,");
          }
        } else {
          buffer.writeln("    ${param.name}: null,");
        }
      }
      buffer.writeln('  );');

      // Assign synthesized properties
      if (timestamps) {
        if (!existsCreatedAt) buffer.writeln("  instance.createdAt = json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null;");
        if (!existsUpdatedAt) buffer.writeln("  instance.updatedAt = json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null;");
      }
      if (paranoid && !existsDeletedAt) {
        buffer.writeln("  instance.deletedAt = json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null;");
      }

      for (final rel in relationships) {
        final isCollection = rel['isCollection'] as bool;
        final fieldName = rel['fieldName'];
        final modelTable = rel['model'];
        final modelClass = rel['modelClass'];

        final existsRel = fields.any((f) => f.name == fieldName);
        final paramRel = constructor.parameters.any((p) => p.name == fieldName);
        if (!existsRel && !paramRel) {
          if (isCollection) {
            buffer
              ..writeln("  if (json['$modelTable'] != null) {")
              ..writeln(
                  "    instance.$fieldName.addAll((json['$modelTable'] as List).map((e) => $modelClass.fromJson(e as Map<String, dynamic>)).toList());")
              ..writeln("  }");
          } else {
            buffer.writeln(
                "  instance._\$$fieldName = json['$modelTable'] != null ? $modelClass.fromJson(json['$modelTable'] as Map<String, dynamic>) : null;");
          }
        }

        if (rel['type'] == 'BelongsTo') {
          final fkName = rel['foreignKeyName'];
          final fkSqlName = rel['foreignKey'];
          final existsFk = fields.any((f) => f.name == fkName);
          final paramFk = constructor.parameters.any((p) => p.name == fkName);
          if (!existsFk && !paramFk) {
            buffer.writeln("  instance.$fkName = json['$fkSqlName'];");
          }
        }
      }

      buffer
        ..writeln('  return instance;')
        ..writeln('}');
    }

    return buffer.toString();
  }

  bool _isColumn(FieldElement field) {
    return field.metadata.any((m) {
      final name = m.element?.enclosingElement3?.name;
      return name == 'Column' ||
          name == 'ID' ||
          name == 'ForeignKey' ||
          name == 'BelongsTo';
    });
  }
}
