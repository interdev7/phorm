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
    'sqflow',
  );
}

Builder standaloneSqlSchemaBuilder(BuilderOptions options) {
  return LibraryBuilder(
    _SqflowCombinedGenerator(),
    generatedExtension: '.sql.g.dart',
  );
}

Builder standaloneSqlFunctionBuilder(BuilderOptions options) {
  return LibraryBuilder(
    SqlFunctionGenerator(),
    generatedExtension: '.fn.g.dart',
  );
}

class _SqflowCombinedGenerator extends Generator {
  final _schemaGen = SqliteSchemaGenerator();
  final _mixinGen = ModelMixinGenerator();

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();

    const schemaChecker = TypeChecker.fromUrl('package:sqflow_platform_interface/src/annotations.dart#Schema');
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

    buffer.writeln(r'''
dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
''');

    return buffer.toString();
  }
}
