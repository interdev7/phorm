import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:phorm_generator/builder.dart';

/// Runs the combined schema + mixin builder over [source] and returns the
/// generated `.sql.g.dart` content for `pkg|lib/model.dart`.
Future<String> generateSchema(String source) async {
  final builder = standaloneSqlSchemaBuilder(BuilderOptions.empty);
  final writer = InMemoryAssetWriter();
  await testBuilder(
    builder,
    {'pkg|lib/model.dart': source},
    writer: writer,
    reader: await PackageAssetReader.currentIsolate(),
  );
  final output = writer.assets[AssetId('pkg', 'lib/model.sql.g.dart')];
  return output == null ? '' : String.fromCharCodes(output);
}

/// Runs the SQL-function builder over [source] and returns the generated
/// `.fn.g.dart` content.
Future<String> generateFunctions(String source) async {
  final builder = standaloneSqlFunctionBuilder(BuilderOptions.empty);
  final writer = InMemoryAssetWriter();
  await testBuilder(
    builder,
    {'pkg|lib/model.dart': source},
    writer: writer,
    reader: await PackageAssetReader.currentIsolate(),
  );
  final output = writer.assets[AssetId('pkg', 'lib/model.fn.g.dart')];
  return output == null ? '' : String.fromCharCodes(output);
}
