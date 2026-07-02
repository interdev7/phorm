import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/function_generator.dart';

/// Generator for custom SQL functions annotated with [SqlFunc].
///
/// Parses the annotated top-level functions and delegates dialect-specific
/// emission to a [FunctionGenerator]. Custom functions are declared at library
/// level (no `@Schema` to read a dialect from), so the dialect currently
/// defaults to SQLite.
class PhormFunctionGenerator extends Generator {
  // TODO(dialect): allow selecting the function dialect (build option or a
  // `dialect` field on `@SqlFunc`) instead of always defaulting to SQLite.
  static const _dialectKind = SqlDialectKind.sqlite;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final functions = <SqlFuncData>[];

    const sqlFuncChecker = TypeChecker.fromUrl(
      'package:phorm_annotations/src/annotations.dart#SqlFunc',
    );

    // Find all top-level functions in the library
    for (final element in library.allElements) {
      if (element is FunctionElement) {
        final annotation = sqlFuncChecker.firstAnnotationOf(element);
        if (annotation == null) continue;

        final reader = ConstantReader(annotation);
        final explicitName = reader.read('name').literalValue as String?;
        final sqlName = explicitName ?? element.name.toUpperCase();

        functions.add(SqlFuncData(element: element, sqlName: sqlName));
      }
    }

    if (functions.isEmpty) {
      return '';
    }

    final dialect = FunctionGenerator.fromKind(_dialectKind);
    final body = dialect.generate(functions);
    if (body.isEmpty) return '';

    // Write the part-of header to bind the generated file with the source file
    final fileName = p.basename(buildStep.inputId.path);
    final buffer =
        StringBuffer()
          ..writeln("part of '$fileName';\n")
          ..write(body);

    return buffer.toString();
  }
}
