// lib/builder.dart
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'src/model_mixin_generator.dart';
import 'src/sql_function_generator.dart';
import 'src/sqlite_schema_generator.dart';

Builder sqlSchemaBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [SqliteSchemaGenerator(), ModelMixinGenerator()],
    'phorm',
  );
}

Builder standaloneSqlSchemaBuilder(BuilderOptions options) {
  return LibraryBuilder(
    _PhormCombinedGenerator(),
    generatedExtension: '.sql.g.dart',
  );
}

Builder standaloneSqlFunctionBuilder(BuilderOptions options) {
  return LibraryBuilder(
    SqlFunctionGenerator(),
    generatedExtension: '.fn.g.dart',
  );
}

class _PhormCombinedGenerator extends Generator {
  final _schemaGen = SqliteSchemaGenerator();
  final _mixinGen = ModelMixinGenerator();

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();

    const schemaChecker = TypeChecker.fromUrl(
        'package:phorm_annotations/src/annotations.dart#Schema');
    var annotated = library.annotatedWith(schemaChecker);

    if (annotated.isEmpty) {
      // Fallback: manually check classes
      final allAnnotated = <AnnotatedElement>[];
      for (final c in library.allElements.whereType<ClassElement>()) {
        final annotation = schemaChecker.firstAnnotationOf(c);
        if (annotation != null) {
          allAnnotated.add(AnnotatedElement(ConstantReader(annotation), c));
        }
      }
      annotated = allAnnotated;
    }

    if (annotated.isEmpty) {
      return '';
    }

    final fileName = p.basename(buildStep.inputId.path);
    buffer.writeln("part of '$fileName';\n");

    for (final annotatedElement in annotated) {
      final schemaResult = await _schemaGen.generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
      buffer.writeln(schemaResult);

      final mixinResult = _mixinGen.generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
      buffer.writeln(mixinResult);
    }

    final generatedContent = buffer.toString();
    final finalBuffer = StringBuffer()..write(generatedContent);

    // Only output _$PhormToJsonValue if it is referenced in the generated models
    if (generatedContent.contains(r'_$PhormToJsonValue')) {
      finalBuffer.writeln(r'''
dynamic _$PhormToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  // Collections and Maps are stored as JSON strings in SQLite
  if (value is List || value is Set || value is Map) {
    return jsonEncode(value is Set ? value.toList() : value);
  }
  return value;
}
''');
    }

    // Only output _$PhormDecodeJson if it is referenced in the generated models (e.g., collections deserialization)
    if (generatedContent.contains(r'_$PhormDecodeJson')) {
      finalBuffer.writeln(r'''
/// Decodes a value from SQLite storage.
/// JSON strings (from List/Set/Map fields) are decoded back to Dart objects.
dynamic _$PhormDecodeJson(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trimLeft();
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        return jsonDecode(value);
      } catch (_) {}
    }
  }
  return value;
}
''');
    }

    return finalBuffer.toString();
  }
}
