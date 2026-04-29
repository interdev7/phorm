// lib/builder.dart
import 'package:path/path.dart' as p;
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/sqlite_schema_generator.dart';
import 'src/model_mixin_generator.dart';
import 'package:sqflow_platform_interface/src/annotations.dart';

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

class _SqflowCombinedGenerator extends Generator {
  final _schemaGen = SqliteSchemaGenerator();
  final _mixinGen = ModelMixinGenerator();

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();
    final annotated = library.annotatedWith(const TypeChecker.fromRuntime(Schema));
    
    if (annotated.isEmpty) return '';

    final fileName = p.basename(buildStep.inputId.path);
    buffer.writeln("part of '$fileName';\n");

    for (final annotatedElement in annotated) {
      final schemaResult = await _schemaGen.generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
      buffer.writeln(schemaResult);

      final mixinResult = await _mixinGen.generateForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
      buffer.writeln(mixinResult);
    }
    
    buffer.writeln(r'''
dynamic _$toJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}

bool _detectSoftDelete(String schema) {
  final normalized = schema.toLowerCase();
  return normalized.contains('deleted_at') && normalized.contains('create table');
}
''');

    return buffer.toString();
  }
}
