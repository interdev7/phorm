import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

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
    final isGeneric = element.typeParameters.isNotEmpty;
    final classType = isGeneric ? '$className<dynamic>' : className;
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
    final paranoid = annotation.peek('paranoid')?.boolValue ?? false;

    final tableName = annotation.peek('tableName')?.stringValue ??
        MetadataExtractor.camelToSnake(className);

    final fields = element.fields.where((f) => !f.isStatic).toList();
    final hasValidators = fields.any((field) {
      final columnMeta = field.metadata.where((m) {
        final name = m.element?.enclosingElement3?.name;
        return name == 'Column' || name == 'ID';
      }).firstOrNull;
      if (columnMeta == null) return false;
      final reader = ConstantReader(columnMeta.computeConstantValue());
      final validatorsReader = reader.peek('validators');
      return validatorsReader != null &&
          validatorsReader.isList &&
          validatorsReader.listValue.isNotEmpty;
    });
    final useValidator =
        (annotation.peek('useValidator')?.boolValue ?? true) && hasValidators;
    final relationships = <Map<String, dynamic>>[];

    // Class level relationships
    final relsReader = annotation.peek('relationships');
    if (relsReader != null && !relsReader.isNull) {
      for (final item in relsReader.listValue) {
        final r = ConstantReader(item);
        final type = item.type!.element!.name;
        final modelClass = MetadataExtractor.resolveModelClass(r.read('model'));
        final isCollection = type == 'HasMany' || type == 'ManyToMany';

        var fieldName = MetadataExtractor.camelToSnake(modelClass);
        if (isCollection && !fieldName.endsWith('s')) {
          fieldName = '${fieldName}s';
        }

        final foreignKey = r.read('foreignKey').stringValue;

        // Resolve the PK SQL name of the related model (used in BelongsTo getter)
        final relatedIdInfo = type == 'BelongsTo'
            ? MetadataExtractor.resolveRelatedIdInfo(r.read('model'), strategy)
            : null;

        relationships.add({
          'type': type,
          'model': MetadataExtractor.resolveModelName(r.read('model')),
          'modelClass': modelClass,
          'isCollection': isCollection,
          'fieldName': fieldName,
          'foreignKey': foreignKey,
          'foreignKeyName': MetadataExtractor.snakeToCamel(foreignKey),
          'relatedPkSqlName': relatedIdInfo?.sqlName ?? 'id',
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
            name == 'ManyToMany' ||
            name == 'Join';
      }).firstOrNull;

      if (relMeta != null) {
        final r = ConstantReader(relMeta.computeConstantValue());
        final type = relMeta.element!.enclosingElement3!.name!;
        var modelClass = MetadataExtractor.resolveModelClass(r.read('model'));
        final fieldTypeStr = field.type.getDisplayString();
        final isCollection = type == 'HasMany' || type == 'ManyToMany';

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

        // Resolve the PK SQL name of the related model (used in BelongsTo getter)
        final relatedIdInfo = type == 'BelongsTo'
            ? MetadataExtractor.resolveRelatedIdInfo(r.read('model'), strategy)
            : null;

        relationships.add({
          'type': type,
          'model': MetadataExtractor.resolveModelName(r.read('model')),
          'modelClass': modelClass,
          'isCollection': isCollection,
          'fieldName': fieldName,
          'foreignKey': foreignKey,
          'foreignKeyName': MetadataExtractor.snakeToCamel(foreignKey),
          'relatedPkSqlName': relatedIdInfo?.sqlName ?? 'id',
        });
      }
    }

    final typeParams = element.typeParameters.map((p) => p.name).join(', ');
    final typeParamsBrackets = typeParams.isNotEmpty ? '<$typeParams>' : '';

    final toJsonTypeParams = element.typeParameters
        .map((p) => 'Object? Function(${p.name} value) toJson${p.name}')
        .join(', ');
    final toJsonArgs =
        element.typeParameters.map((p) => 'toJson${p.name}').join(', ');

    final fromJsonTypeParams = element.typeParameters
        .map((p) => '${p.name} Function(Object? json) fromJson${p.name}')
        .join(', ');

    final buffer = StringBuffer()
      ..writeln('mixin _\$Phorm${className}Mixin$typeParamsBrackets {');

    if (useToJson) {
      final paramList = toJsonTypeParams.isNotEmpty
          ? '[${element.typeParameters.map((p) => 'Object? Function(${p.name} value)? toJson${p.name}').join(', ')}]'
          : '';
      final argList = toJsonArgs.isNotEmpty
          ? ', ${element.typeParameters.map((p) => 'toJson${p.name} ?? (x) => x').join(', ')}'
          : '';
      buffer
        ..writeln()
        ..writeln(
            '  Map<String, dynamic> toJson($paramList) => _\$Phorm${className}ToJson(this as $className$typeParamsBrackets$argList);');
    }

    if (useToString) {
      buffer
        ..writeln()
        ..writeln('  @override')
        ..writeln(
            '  String toString() => _\$Phorm${className}ToString(this as $className$typeParamsBrackets);');
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
          // Use toJson() to get the related model's PK by its SQL column name,
          // matching the approach used in SqflowCore (item.toJson()[table.primaryKey])
          final relatedPk = rel['relatedPkSqlName'] as String? ?? 'id';
          buffer
            ..writeln('  var _\$$fkName;')
            ..writeln(
                "  dynamic get $fkName => $fieldName?.toJson()['$relatedPk'] ?? _\$$fkName;")
            ..writeln('  set $fkName(dynamic value) => _\$$fkName = value;');
        }
      }
    }

    // Close the mixin
    buffer.writeln('}');

    // 2. Helper functions for JSON and String serialization
    if (useToJson) {
      final paramList =
          toJsonTypeParams.isNotEmpty ? ', $toJsonTypeParams' : '';
      buffer
        ..writeln()
        ..writeln(
            'Map<String, dynamic> _\$Phorm${className}ToJson$typeParamsBrackets($className$typeParamsBrackets instance$paramList) {')
        ..writeln('  final ${className.toLowerCase()}Json = {');
      for (final field in fields) {
        if (relationships.any((r) => r['fieldName'] == field.name)) continue;

        final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
        final info = MetadataExtractor.getConverterInfo(field);
        // For generic type parameters (T), pass the corresponding toJsonT function
        final toJsonParam = field.type is TypeParameterType
            ? 'toJson${(field.type as TypeParameterType).element.name}'
            : null;
        final valueExpr = _generateToJsonValue(
          field.type,
          'instance.${field.name}',
          info: info,
          toJsonParamName: toJsonParam,
        );
        buffer.writeln("    '$sqlName': _\$PhormToJsonValue($valueExpr),");
      }

      if (timestamps) {
        if (!existsCreatedAt) {
          buffer.writeln(
              r"    'created_at': _$PhormToJsonValue(instance.createdAt),");
        }
        if (!existsUpdatedAt) {
          buffer.writeln(
              r"    'updated_at': _$PhormToJsonValue(instance.updatedAt),");
        }
      }
      if (paranoid && !existsDeletedAt) {
        buffer.writeln(
            r"    'deleted_at': _$PhormToJsonValue(instance.deletedAt),");
      }

      // Output synthesized foreign keys in toJson
      for (final rel in relationships) {
        if (rel['type'] == 'BelongsTo') {
          final fkName = rel['foreignKeyName'];
          final fkSqlName = rel['foreignKey'];
          final existsFk = fields.any((f) => f.name == fkName);
          if (!existsFk) {
            buffer.writeln(
                "    '$fkSqlName': _\$PhormToJsonValue(instance.$fkName),");
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
        ..writeln(
            'String _\$Phorm${className}ToString$typeParamsBrackets($className$typeParamsBrackets instance) {')
        ..writeln('  return """')
        ..writeln('$className(');

      for (final field in fields) {
        buffer.writeln('  ${field.name}: \${instance.${field.name}},');
      }

      if (timestamps) {
        if (!existsCreatedAt) {
          buffer.writeln(r'  createdAt: ${instance.createdAt},');
        }
        if (!existsUpdatedAt) {
          buffer.writeln(r'  updatedAt: ${instance.updatedAt},');
        }
      }
      if (paranoid && !existsDeletedAt) {
        buffer.writeln(r'  deletedAt: ${instance.deletedAt},');
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
        ..writeln(
            'extension Phorm${className}Ext$typeParamsBrackets on $className$typeParamsBrackets {');

      final constructor =
          element.unnamedConstructor ?? element.constructors.first;
      buffer.writeln('  $className$typeParamsBrackets copyWith({');

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
                ? 'PhormJSONValidatorException'
                : 'PhormCHECKValidatorException';

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
      final paramList =
          fromJsonTypeParams.isNotEmpty ? ', $fromJsonTypeParams' : '';
      buffer
        ..writeln(
            '\n$className$typeParamsBrackets _\$Phorm${className}FromJson$typeParamsBrackets(Map<String, dynamic> json$paramList) {')
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
        } else if (field != null) {
          final sqlName = MetadataExtractor.getSqlColumnName(field, strategy);
          final info = MetadataExtractor.getConverterInfo(field);
          // For generic type parameters (T), pass the corresponding fromJsonT function
          final fromJsonParam = param.type is TypeParameterType
              ? 'fromJson${(param.type as TypeParameterType).element.name}'
              : null;
          final parsedExpr = _generateFromJsonValue(
            param.type,
            "json['$sqlName']",
            info: info,
            fromJsonParamName: fromJsonParam,
          );
          buffer.writeln("    ${param.name}: $parsedExpr,");
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
          "  static const PhormColumn<$type> ${field.name} = PhormColumn<$type>('$sqlName', tableName: '$tableName');");
    }

    if (timestamps) {
      if (!existsCreatedAt) {
        buffer.writeln(
            "  static const PhormColumn<DateTime> createdAt = PhormColumn<DateTime>('created_at', tableName: '$tableName');");
      }
      if (!existsUpdatedAt) {
        buffer.writeln(
            "  static const PhormColumn<DateTime> updatedAt = PhormColumn<DateTime>('updated_at', tableName: '$tableName');");
      }
    }
    if (paranoid && !existsDeletedAt) {
      buffer.writeln(
          "  static const PhormColumn<DateTime> deletedAt = PhormColumn<DateTime>('deleted_at', tableName: '$tableName');");
    }

    // Synthesized FKs
    for (final rel in relationships) {
      if (rel['type'] == 'BelongsTo') {
        final fkName = rel['foreignKeyName'] as String;
        final fkSqlName = rel['foreignKey'] as String;
        final existsFk = fields.any((f) => f.name == fkName);
        if (!existsFk) {
          buffer.writeln(
              "  static const PhormColumn<dynamic> $fkName = PhormColumn<dynamic>('$fkSqlName', tableName: '$tableName');");
        }
      }
    }

    buffer
      ..writeln()
      ..writeln(
          '  static PhormCore<$classType> get _service => PhormCore<$classType>(dbManager: appDb, table: ${tableName}Table);')
      ..writeln()
      ..writeln(
          '  static PhormQuery<$classType> where(PhormCondition condition) => _service.where(condition);')
      ..writeln('  static PhormQuery<$classType> get query => _service.query;')
      ..writeln()
      ..writeln(
          '  static Future<int> insert($classType item, {DatabaseExecutor? executor}) => _service.insert(item, executor: executor);')
      ..writeln(
          '  static Future<int> update($classType item, {DatabaseExecutor? executor}) => _service.update(item, executor: executor);')
      ..writeln(
          '  static Future<void> upsert($classType item, {DatabaseExecutor? executor}) => _service.upsert(item, executor: executor);')
      ..writeln(
          '  static Future<int> delete(Object id, {bool force = false, DatabaseExecutor? executor}) => _service.delete(id, force: force, executor: executor);')
      ..writeln(
          '  static Future<int> restore(Object id, {DatabaseExecutor? executor}) => _service.restore(id, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<int> insertBatch(List<$classType> items, {DatabaseExecutor? executor}) => _service.insertBatch(items, executor: executor);')
      ..writeln(
          '  static Future<int> updateBatch(List<$classType> items, {DatabaseExecutor? executor}) => _service.updateBatch(items, executor: executor);')
      ..writeln(
          '  static Future<int> upsertBatch(List<$classType> items, {DatabaseExecutor? executor}) => _service.upsertBatch(items, executor: executor);')
      ..writeln(
          '  static Future<int> deleteBatch(List<Object> ids, {bool force = false, DatabaseExecutor? executor}) => _service.deleteBatch(ids, force: force, executor: executor);');

    if (paranoid) {
      buffer.writeln(
          '  static Future<int> restoreBatch(List<Object> ids, {DatabaseExecutor? executor}) => _service.restoreBatch(ids, executor: executor);');
    }

    buffer
      ..writeln()
      ..writeln(
          '  static Future<bool> exists(Object id, {bool withDeleted = false, DatabaseExecutor? executor}) => _service.exists(id, withDeleted: withDeleted, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<$classType?> readOne(Object id, {List<String>? columns, Attributes? attributes, bool withDeleted = false, List<Includable>? include, DatabaseExecutor? executor}) => ')
      ..writeln(
          '    _service.readOne(id, columns: columns, attributes: attributes, withDeleted: withDeleted, include: include, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<Result<$classType>> readAll({int limit = 20, int offset = 0, WhereBuilder? where, SortBuilder? sort, List<String>? columns, Attributes? attributes, bool withDeleted = false, bool onlyDeleted = false, List<Includable>? include, DatabaseExecutor? executor}) => ')
      ..writeln(
          '    _service.readAll(limit: limit, offset: offset, where: where, sort: sort, columns: columns, attributes: attributes, withDeleted: withDeleted, onlyDeleted: onlyDeleted, include: include, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<ResultWithCount<$classType>> readAllWithCount({int limit = 20, int offset = 0, WhereBuilder? where, SortBuilder? sort, List<String>? columns, Attributes? attributes, bool withDeleted = false, bool onlyDeleted = false, List<Includable>? include, DatabaseExecutor? executor}) => ')
      ..writeln(
          '    _service.readAllWithCount(limit: limit, offset: offset, where: where, sort: sort, columns: columns, attributes: attributes, withDeleted: withDeleted, onlyDeleted: onlyDeleted, include: include, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<int> count({Object? column, WhereBuilder? where, DatabaseExecutor? executor}) => _service.count(column: column, where: where, executor: executor);')
      ..writeln(
          '  static Future<num> sum(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.sum(column, where: where, executor: executor);')
      ..writeln(
          '  static Future<num> avg(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.avg(column, where: where, executor: executor);')
      ..writeln(
          '  static Future<num> min(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.min(column, where: where, executor: executor);')
      ..writeln(
          '  static Future<num> max(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.max(column, where: where, executor: executor);')
      ..writeln()
      ..writeln(
          '  static Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) => _service.transaction(action);')
      ..writeln()
      ..writeln(
          '  static Stream<String> get changeStream => _service.dbManager.changeStream;')
      ..writeln(
          '  static Stream<$classType?> watchOne(Object id, {List<Includable>? include}) => _service.watchOne(id, include: include);')
      ..writeln(
          '  static Stream<List<$classType>> watchAll({WhereBuilder? where, List<Includable>? include, SortBuilder? sort, int? limit}) => ')
      ..writeln(
          '    _service.watchAll(where: where, include: include, sort: sort, limit: limit);')
      ..writeln('}');

    if (relationships.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
            'extension ${className}QueryRelations on PhormQuery<$classType> {');
      for (final rel in relationships) {
        final fieldName = rel['fieldName'] as String;
        final modelClass = rel['modelClass'] as String;
        final capitalized = fieldName[0].toUpperCase() + fieldName.substring(1);
        final methodName = 'include$capitalized';

        buffer.writeln('''
  PhormQuery<$classType> $methodName({Attributes? attributes, List<Includable>? include}) {
    return includeOne(Includable.model<$modelClass>(attributes: attributes, include: include));
  }''');
      }
      buffer.writeln('}');
    }

    return buffer.toString();
  }

  String _generateToJsonValue(
    DartType type,
    String accessor, {
    ConverterInfo? info,
    // Для generic-полей типа T передаётся имя соответствующего функции-параметра
    String? toJsonParamName,
  }) {
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;
    final q = isNullable ? '?' : '';

    // Custom converter
    if (info != null) {
      if (isNullable) {
        return "$accessor != null ? ${info.code}.toSql($accessor!) : null";
      }
      return "${info.code}.toSql($accessor)";
    }

    // Generic type parameter (T, E, etc.)
    if (type is TypeParameterType) {
      // Use the passed-in toJsonT function if provided
      if (toJsonParamName != null) {
        if (isNullable) {
          return "$accessor != null ? $toJsonParamName($accessor as ${type.element.name}) : null";
        }
        return "$toJsonParamName($accessor)";
      }
      return accessor;
    }

    if (type.element is EnumElement || type.element?.kind.name == 'ENUM') {
      return "$accessor$q.name";
    }

    final typeName = type.element?.name;

    if (typeName == 'DateTime') return accessor;
    if (typeName == 'BigInt') return "$accessor$q.toString()";
    if (typeName == 'Uri') return "$accessor$q.toString()";
    if (typeName == 'Duration') return "$accessor$q.inMicroseconds";

    // Basic types — pass through as-is
    if (type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreBool ||
        type.isDartCoreString ||
        type.isDartCoreNum) {
      return accessor;
    }

    // List / Set / Iterable
    if (type is ParameterizedType &&
        (typeName == 'List' || typeName == 'Set' || typeName == 'Iterable') &&
        type.typeArguments.isNotEmpty) {
      final itemType = type.typeArguments.first;
      final itemExpr = _generateToJsonValue(itemType, 'e');
      final sameExpr = itemExpr == 'e';
      if (isNullable) {
        return sameExpr
            ? accessor
            : "$accessor$q.map((e) => $itemExpr).toList()";
      }
      return sameExpr ? accessor : "$accessor.map((e) => $itemExpr).toList()";
    }

    // Map<String, V>
    if (type is ParameterizedType &&
        typeName == 'Map' &&
        type.typeArguments.length == 2) {
      final valueType = type.typeArguments[1];
      final valExpr = _generateToJsonValue(valueType, 'v');
      if (valExpr == 'v') return accessor;
      return "$accessor$q.map((k, v) => MapEntry(k, $valExpr))";
    }

    // Class with toJson()
    if (type.element is ClassElement &&
        typeName != 'Object' &&
        typeName != 'dynamic') {
      final classElement = type.element as ClassElement;
      final hasToJson = classElement.methods.any((m) => m.name == 'toJson');
      if (hasToJson) {
        return "$accessor$q.toJson()";
      }
    }

    return accessor;
  }

  String _generateFromJsonValue(
    DartType type,
    String jsonAccess, {
    ConverterInfo? info,
    // Для generic-полей T передаётся имя функции-параметра fromJsonT
    String? fromJsonParamName,
  }) {
    final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;
    final typeName = type.element?.name;
    final displayType = type.getDisplayString();
    final rawType = displayType.replaceAll('?', '');

    // Custom converter
    if (info != null) {
      final sType = info.sqlType.getDisplayString();
      if (isNullable) {
        return "$jsonAccess != null ? ${info.code}.fromSql($jsonAccess as $sType) : null";
      }
      return "${info.code}.fromSql($jsonAccess as $sType)";
    }

    // Generic type parameter (T, E, etc.)
    if (type is TypeParameterType) {
      if (fromJsonParamName != null) {
        if (isNullable) {
          return "$jsonAccess != null ? $fromJsonParamName($jsonAccess) : null";
        }
        return "$fromJsonParamName($jsonAccess)";
      }
      // Fallback — no converter provided
      return "$jsonAccess as $displayType";
    }

    // Enum
    if (type.element is EnumElement || type.element?.kind.name == 'ENUM') {
      if (isNullable) {
        return "$jsonAccess != null ? $rawType.values.byName($jsonAccess as String) : null";
      }
      return "$rawType.values.byName($jsonAccess as String)";
    }

    // DateTime
    if (typeName == 'DateTime') {
      if (isNullable) {
        return "$jsonAccess != null ? DateTime.parse($jsonAccess as String) : null";
      }
      return "DateTime.parse($jsonAccess as String)";
    }

    // BigInt
    if (typeName == 'BigInt') {
      if (isNullable) {
        return "$jsonAccess != null ? BigInt.parse($jsonAccess as String) : null";
      }
      return "BigInt.parse($jsonAccess as String)";
    }

    // Uri
    if (typeName == 'Uri') {
      if (isNullable) {
        return "$jsonAccess != null ? Uri.parse($jsonAccess as String) : null";
      }
      return "Uri.parse($jsonAccess as String)";
    }

    // Duration (stored as microseconds int)
    if (typeName == 'Duration') {
      if (isNullable) {
        return "$jsonAccess != null ? Duration(microseconds: $jsonAccess as int) : null";
      }
      return "Duration(microseconds: $jsonAccess as int)";
    }

    // bool (SQLite stores as 0/1)
    if (typeName == 'bool') {
      if (isNullable) {
        return "$jsonAccess == null ? null : ($jsonAccess is bool ? $jsonAccess as bool : ($jsonAccess as int) == 1)";
      }
      return "$jsonAccess is bool ? $jsonAccess as bool : ($jsonAccess as int) == 1";
    }

    // Core scalar types
    if (type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreString ||
        type.isDartCoreNum) {
      return "$jsonAccess as $displayType";
    }

    // List<T>
    if (type is ParameterizedType &&
        typeName == 'List' &&
        type.typeArguments.isNotEmpty) {
      final itemType = type.typeArguments.first;
      final itemExpr = _generateFromJsonValue(itemType, 'e');
      if (isNullable) {
        return "(_\$PhormDecodeJson($jsonAccess) as List?)?.map((e) => $itemExpr).toList()";
      }
      return "(_\$PhormDecodeJson($jsonAccess) as List).map((e) => $itemExpr).toList()";
    }

    // Set<T>
    if (type is ParameterizedType &&
        typeName == 'Set' &&
        type.typeArguments.isNotEmpty) {
      final itemType = type.typeArguments.first;
      final itemExpr = _generateFromJsonValue(itemType, 'e');
      if (isNullable) {
        return "(_\$PhormDecodeJson($jsonAccess) as List?)?.map((e) => $itemExpr).toSet()";
      }
      return "(_\$PhormDecodeJson($jsonAccess) as List).map((e) => $itemExpr).toSet()";
    }

    // Map<String, V>
    if (type is ParameterizedType &&
        typeName == 'Map' &&
        type.typeArguments.length == 2) {
      final valueType = type.typeArguments[1];
      final valExpr = _generateFromJsonValue(valueType, 'v');
      if (isNullable) {
        return "(_\$PhormDecodeJson($jsonAccess) as Map?)?.map((k, v) => MapEntry(k as String, $valExpr))";
      }
      return "(_\$PhormDecodeJson($jsonAccess) as Map).map((k, v) => MapEntry(k as String, $valExpr))";
    }

    // Nested class with fromJson constructor
    if (type.element is ClassElement &&
        typeName != 'Object' &&
        typeName != 'dynamic') {
      final classElement = type.element as ClassElement;
      final hasFromJson =
          classElement.constructors.any((c) => c.name == 'fromJson');
      if (hasFromJson) {
        if (isNullable) {
          return "$jsonAccess != null ? $rawType.fromJson($jsonAccess as Map<String, dynamic>) : null";
        }
        return "$rawType.fromJson($jsonAccess as Map<String, dynamic>)";
      }
    }

    // Fallback
    return "$jsonAccess as $displayType";
  }

  bool _isColumn(FieldElement field) {
    return MetadataExtractor.columnChecker.hasAnnotationOf(field) ||
        MetadataExtractor.idChecker.hasAnnotationOf(field) ||
        MetadataExtractor.foreignKeyChecker.hasAnnotationOf(field) ||
        MetadataExtractor.belongsToChecker.hasAnnotationOf(field);
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
