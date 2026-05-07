import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'dart:convert';
import 'package:source_gen/source_gen.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

import 'metadata_extractor.dart';

const _jsonValidatorChecker = TypeChecker.fromRuntime(IJsonValidator);

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
    final useCopyWith = annotation.peek('useCopyWith')?.boolValue ?? true;
    final useToString = annotation.peek('useToString')?.boolValue ?? true;
    final timestamps = annotation.peek('timestamps')?.boolValue ?? true;
    final useValidator = annotation.peek('useValidator')?.boolValue ?? true;
    final paranoid = annotation.peek('paranoid')?.boolValue ?? false;

    final tableName = annotation.peek('tableName')?.stringValue ??
        MetadataExtractor.camelToSnake(className);

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

    final buffer = StringBuffer()
      ..writeln('mixin _\$SQFlow${className}Mixin {');


    if (useToJson) {
      buffer
        ..writeln()
        ..writeln('  Map<String, dynamic> toJson() => _\$SQFlow${className}ToJson(this as $className);');
    }

    if (useToString) {
      buffer
        ..writeln()
        ..writeln('  @override')
        ..writeln(
            '  String toString() => _\$SQFlow${className}ToString(this as $className);');
    }

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

    // 2. Helper functions for JSON and String serialization
    if (useToJson) {
      buffer
        ..writeln()
        ..writeln(
            'Map<String, dynamic> _\$SQFlow${className}ToJson($className instance) {')
        ..writeln('  final ${className.toLowerCase()}Json = {');
      for (final field in fields.where((f) => _isColumn(f))) {
        final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
        buffer.writeln(
            "    '$sqlName': _\$SQFlowToJsonValue(instance.${field.name}),");
      }

      if (timestamps) {
        if (!existsCreatedAt) {
          buffer.writeln(
              r"    'created_at': _$SQFlowToJsonValue(instance.createdAt),");
        }
        if (!existsUpdatedAt) {
          buffer.writeln(
              r"    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),");
        }
      }
      if (paranoid && !existsDeletedAt) {
        buffer.writeln(
            r"    'deleted_at': _$SQFlowToJsonValue(instance.deletedAt),");
      }

      // Output synthesized foreign keys in toJson
      for (final rel in relationships) {
        if (rel['type'] == 'BelongsTo') {
          final fkName = rel['foreignKeyName'];
          final fkSqlName = rel['foreignKey'];
          final existsFk = fields.any((f) => f.name == fkName);
          if (!existsFk) {
            buffer.writeln(
                "    '$fkSqlName': _\$SQFlowToJsonValue(instance.$fkName),");
          }
        }
      }

      buffer
        ..writeln('  };')
        ..writeln(useValidator
            ? "  _\$validate$className(${className.toLowerCase()}Json, tableName: '$tableName');\n"
            : '')
        ..writeln('  return ${className.toLowerCase()}Json;')
        ..writeln('}');
    }

    if (useToString) {
      buffer
        ..writeln()
        ..writeln('String _\$SQFlow${className}ToString($className instance) {')
        ..writeln('  return """')
        ..writeln('$className(');

      for (final field in fields) {
        buffer.writeln('  ${field.name}: \${instance.${field.name}},');
      }

      if (timestamps) {
        if (!existsCreatedAt)
          buffer.writeln('  createdAt: \${instance.createdAt},');
        if (!existsUpdatedAt)
          buffer.writeln('  updatedAt: \${instance.updatedAt},');
      }
      if (paranoid && !existsDeletedAt) {
        buffer.writeln('  deletedAt: \${instance.deletedAt},');
      }

      for (final rel in relationships) {
        final fieldName = rel['fieldName'];
        final exists = fields.any((f) => f.name == fieldName);
        if (!exists) {
          buffer.writeln('  $fieldName: \${instance.$fieldName},');
        }
        if (rel['type'] == 'BelongsTo') {
          final fkName = rel['foreignKeyName'];
          final existsFk = fields.any((f) => f.name == fkName);
          if (!existsFk) {
            buffer.writeln('  $fkName: \${instance.$fkName},');
          }
        }
      }

      buffer
        ..writeln(')""";')
        ..writeln('}');
    }

    // 3. Extension for CopyWith
    if (useCopyWith) {
      buffer
        ..writeln()
        ..writeln('extension SQFlow${className}Ext on $className {');

      final constructor =
          element.unnamedConstructor ?? element.constructors.first;
      buffer.writeln('  $className copyWith({');

      for (final param in constructor.parameters) {
        final type = param.type.getDisplayString();
        final copyType = type.endsWith('?') ? type : '$type?';
        buffer.writeln('    $copyType ${param.name},');
      }

      if (timestamps) {
        if (!existsCreatedAt) buffer.writeln('    DateTime? createdAt,');
        if (!existsUpdatedAt) buffer.writeln('    DateTime? updatedAt,');
      }
      if (paranoid && !existsDeletedAt) {
        buffer.writeln('    DateTime? deletedAt,');
      }

      buffer
        ..writeln('  }) {')
        ..writeln('    return $className(');

      for (final param in constructor.parameters) {
        buffer.writeln(
            '      ${param.name}: ${param.name} ?? this.${param.name},');
      }

      buffer.write('    )');

      if (timestamps) {
        if (!existsCreatedAt) {
          buffer.write('\n      ..createdAt = createdAt ?? this.createdAt');
        }
        if (!existsUpdatedAt) {
          buffer.write('\n      ..updatedAt = updatedAt ?? this.updatedAt');
        }
      }
      if (paranoid && !existsDeletedAt) {
        buffer.write('\n      ..deletedAt = deletedAt ?? this.deletedAt');
      }

      buffer
        ..writeln(';')
        ..writeln('  }')
        ..writeln('}');
    }

    // 3. Validation Method
    if (useValidator) {
      buffer.writeln(
          '\nvoid _\$validate$className(Map<String, dynamic> json, {required String tableName}) {');
      for (final field in fields) {
        final columnMeta = field.metadata.where((m) {
          final name = m.element?.enclosingElement3?.name;
          return name == 'Column' || name == 'ID';
        }).firstOrNull;

        if (columnMeta == null) continue;

        final reader = ConstantReader(columnMeta.computeConstantValue());
        final validatorsReader = reader.peek('validators');

        if (validatorsReader != null && validatorsReader.isList) {
          final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);

          for (final validatorObj in validatorsReader.listValue) {
            final validatorReader = ConstantReader(validatorObj);
            final revived = validatorReader.revive();
            final constString = _reviveToCheckCode(revived);

            final isJsonValidator =
                _jsonValidatorChecker.isAssignableFromType(validatorObj.type!);
            final exceptionType = isJsonValidator
                ? 'SqflowJSONValidatorException'
                : 'SqflowCHECKValidatorException';

            // final isNullable =
            //   field.type.nullabilitySuffix == NullabilitySuffix.question;
            // if (!isNullable) { ... }

            buffer
              ..writeln(
                  "  if (!const $constString.isValid(json['$sqlName'])) {")
              ..writeln('    throw $exceptionType(')
              ..writeln('      table: tableName,')
              ..writeln("      column: '$sqlName',")
              ..writeln(
                  '      message: \'Value "\${json[\'$sqlName\']}" failed validation\',');

            final constraint = validatorReader.peek('constraint')?.stringValue;
            if (constraint != null) {
              buffer.writeln("      constraint: '$constraint',");
            }
            buffer
              ..writeln('    );')
              ..writeln('  }');
          }
        }
      }
      buffer.writeln('}');
    }

    // 4. fromJson Function
    if (useFromJson) {
      buffer
        ..writeln(
            '\n$className _\$SQFlow${className}FromJson(Map<String, dynamic> json) {')
        // ..writeln(useValidator
        //     ? '  _\$validate$className(json, tableName: \'$tableName\');\n'
        //     : '')
        ..writeln('  final instance = $className(');

      final constructor =
          element.unnamedConstructor ?? element.constructors.first;
      for (final param in constructor.parameters) {
        final FieldElement? field =
            fields.where((f) => f.name == param.name).firstOrNull;

        final rel = relationships
            .where((r) => r['fieldName'] == param.name)
            .firstOrNull;
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
      buffer.write('  )');

      // Assign synthesized properties with cascade
      if (timestamps) {
        if (!existsCreatedAt) {
          buffer.write(
              "\n    ..createdAt = json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null");
        }
        if (!existsUpdatedAt) {
          buffer.write(
              "\n    ..updatedAt = json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null");
        }
      }
      if (paranoid && !existsDeletedAt) {
        buffer.write(
            "\n    ..deletedAt = json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null");
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
            buffer.write(
                "\n    ..$fieldName.addAll(json['$modelTable'] != null ? (json['$modelTable'] as List).map((e) => $modelClass.fromJson(e as Map<String, dynamic>)).toList() : [])");
          } else {
            buffer.write(
                "\n    .._\$$fieldName = json['$modelTable'] != null ? $modelClass.fromJson(json['$modelTable'] as Map<String, dynamic>) : null");
          }
        }

        if (rel['type'] == 'BelongsTo') {
          final fkName = rel['foreignKeyName'];
          final fkSqlName = rel['foreignKey'];
          final existsFk = fields.any((f) => f.name == fkName);
          final paramFk = constructor.parameters.any((p) => p.name == fkName);
          if (!existsFk && !paramFk) {
            buffer.write("\n    ..$fkName = json['$fkSqlName']");
          }
        }
      }

      buffer
        ..writeln(';')
        ..writeln('  return instance;')
        ..writeln('}');
    }


    // 5. Pluralized service object (e.g. Posts)
    final serviceName = tableName
        .split('_')
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join();
    buffer
      ..writeln()
      ..writeln('/// Pluralized service for $className')
      ..writeln('class $serviceName {');

    // Add Columns to Service Class
    for (final field in fields.where((f) => _isColumn(f))) {
      final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
      var type = field.type.getDisplayString();
      if (type.endsWith('?')) type = type.substring(0, type.length - 1);
      buffer.writeln(
          "  static const SqflowColumn<$type> ${field.name} = SqflowColumn<$type>('$sqlName');");
    }

    if (timestamps) {
      if (!existsCreatedAt) {
        buffer.writeln(
            "  static const SqflowColumn<DateTime> createdAt = SqflowColumn<DateTime>('created_at');");
      }
      if (!existsUpdatedAt) {
        buffer.writeln(
            "  static const SqflowColumn<DateTime> updatedAt = SqflowColumn<DateTime>('updated_at');");
      }
    }
    if (paranoid && !existsDeletedAt) {
      buffer.writeln(
          "  static const SqflowColumn<DateTime> deletedAt = SqflowColumn<DateTime>('deleted_at');");
    }

    // Synthesized FKs
    for (final rel in relationships) {
      if (rel['type'] == 'BelongsTo') {
        final fkName = rel['foreignKeyName'] as String;
        final fkSqlName = rel['foreignKey'] as String;
        final existsFk = fields.any((f) => f.name == fkName);
        if (!existsFk) {
          buffer.writeln(
              "  static const SqflowColumn<dynamic> $fkName = SqflowColumn<dynamic>('$fkSqlName');");
        }
      }
    }

    buffer
      ..writeln()
      ..writeln(
          '  static SqflowCore<$className> get _service => SqflowCore<$className>(dbManager: appDb, table: ${tableName}Table);')
      ..writeln()
      ..writeln(
          '  static SqflowQuery<$className> where(SqflowCondition condition) => _service.where(condition);')
      ..writeln('  static SqflowQuery<$className> get query => _service.query;')
      ..writeln()
      ..writeln(
          '  static Future<int> insert($className item, {DatabaseExecutor? executor}) => _service.insertAsync(item, executor: executor);')
      ..writeln(
          '  static Future<int> update($className item, {DatabaseExecutor? executor}) => _service.updateAsync(item, executor: executor);')
      ..writeln(
          '  static Future<void> upsert($className item, {DatabaseExecutor? executor}) => _service.upsertAsync(item, executor: executor);')
      ..writeln(
          '  static Future<int> delete(Object id, {bool force = false, DatabaseExecutor? executor}) => _service.deleteAsync(id, force: force, executor: executor);')
      ..writeln(
          '  static Future<int> restore(Object id, {DatabaseExecutor? executor}) => _service.restoreAsync(id, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<$className?> read(Object id, {List<String>? columns, Attributes? attributes, bool withDeleted = false, List<Includable>? include, DatabaseExecutor? executor}) => ')
      ..writeln(
          '    _service.readAsync(id, columns: columns, attributes: attributes, withDeleted: withDeleted, include: include, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<Result<$className>> readAll({int limit = 20, int offset = 0, WhereBuilder? where, SortBuilder? sort, List<String>? columns, Attributes? attributes, bool withDeleted = false, bool onlyDeleted = false, List<Includable>? include, DatabaseExecutor? executor}) => ')
      ..writeln(
          '    _service.readAll(limit: limit, offset: offset, where: where, sort: sort, columns: columns, attributes: attributes, withDeleted: withDeleted, onlyDeleted: onlyDeleted, include: include, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<ResultWithCount<$className>> readAllWithCount({int limit = 20, int offset = 0, WhereBuilder? where, SortBuilder? sort, List<String>? columns, Attributes? attributes, bool withDeleted = false, bool onlyDeleted = false, List<Includable>? include, DatabaseExecutor? executor}) => ')
      ..writeln(
          '    _service.readAllWithCount(limit: limit, offset: offset, where: where, sort: sort, columns: columns, attributes: attributes, withDeleted: withDeleted, onlyDeleted: onlyDeleted, include: include, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<int> count({Object? column, WhereBuilder? where, DatabaseExecutor? executor}) => _service.countAsync(column: column, where: where, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) => _service.transaction(action);')
      ..writeln()
      ..writeln(
          '  static Stream<String> get changeStream => _service.dbManager.changeStream;')
      ..writeln(
          '  static Stream<$className?> watch(Object id, {List<Includable>? include}) => _service.watch(id, include: include);')
      ..writeln(
          '  static Stream<List<$className>> watchAll({WhereBuilder? where, List<Includable>? include, SortBuilder? sort, int? limit}) => ')
      ..writeln(
          '    _service.watchAll(where: where, include: include, sort: sort, limit: limit);')
      ..writeln('}');

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

  String _reviveToCheckCode(Revivable revived) {
    final typeName = revived.source.fragment;
    final posArgs =
        revived.positionalArguments.map((a) => _formatConstant(a)).join(', ');
    final namedArgs = revived.namedArguments.entries
        .map((e) => "${e.key}: ${_formatConstant(e.value)}")
        .join(', ');

    final allArgs = [
      if (posArgs.isNotEmpty) posArgs,
      if (namedArgs.isNotEmpty) namedArgs
    ].join(', ');
    return "$typeName($allArgs)";
  }

  String _formatConstant(dynamic obj) {
    final reader =
        obj is ConstantReader ? obj : ConstantReader(obj as DartObject);
    if (reader.isString) return jsonEncode(reader.stringValue);
    if (reader.isBool) return reader.boolValue.toString();
    if (reader.isInt) return reader.intValue.toString();
    if (reader.isDouble) return reader.doubleValue.toString();
    if (reader.isList) {
      return "[${reader.listValue.map((v) => _formatConstant(v)).join(', ')}]";
    }
    // Handle nested ICHECK (e.g. CheckNot)
    try {
      final revived = reader.revive();
      return "const ${_reviveToCheckCode(revived)}";
    } catch (_) {
      return obj.toString();
    }
  }
}
