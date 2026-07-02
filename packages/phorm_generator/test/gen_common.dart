import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:phorm_generator/builder.dart';
import 'package:phorm_generator/src/phorm_function_generator.dart';
import 'package:source_gen/source_gen.dart';

/// A minimal [BuildStep] exposing only [inputId] — the only member the PHORM
/// generators read. Everything else throws via [noSuchMethod].
class _FakeBuildStep implements BuildStep {
  @override
  AssetId get inputId => AssetId('phorm_generator', 'lib/model.dart');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs the real combined schema + mixin generator over [source] and returns
/// the generated Dart source.
///
/// Uses `resolveSource` with all package sources available so that
/// `package:phorm_annotations` annotations resolve under analyzer 13 /
/// build_test 3.x, then drives [PhormCombinedGenerator] directly (the same
/// generator [standaloneSqlSchemaBuilder] wraps).
Future<String> generateSchema(String source) async {
  var output = '';
  await resolveSource(
    source,
    (resolver) async {
      final lib = await resolver.libraries.firstWhere(
        (l) => l.uri.toString().contains('_resolve_source'),
      );
      output = await PhormCombinedGenerator().generate(
        LibraryReader(lib),
        _FakeBuildStep(),
      );
    },
    readAllSourcesFromFilesystem: true,
  );
  return output;
}

/// Runs the SQL-function generator over [source] and returns the generated
/// Dart source (empty when there are no `@SqlFunc` functions).
Future<String> generateFunctions(String source) async {
  var output = '';
  await resolveSource(
    source,
    (resolver) async {
      final lib = await resolver.libraries.firstWhere(
        (l) => l.uri.toString().contains('_resolve_source'),
      );
      output = await PhormFunctionGenerator().generate(
        LibraryReader(lib),
        _FakeBuildStep(),
      );
    },
    readAllSourcesFromFilesystem: true,
  );
  return output;
}
