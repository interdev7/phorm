// lib/builder.dart
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/sql_schema_generator.dart';

Builder sqlSchemaBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [SqlSchemaGenerator()],
    'sql_schema',
  );
}

Builder standaloneSqlSchemaBuilder(BuilderOptions options) {
  return LibraryBuilder(
    SqlSchemaGenerator(),
    generatedExtension: '.sql.g.dart',
  );
}
