// lib/builder.dart
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/sqlite_schema_generator.dart';

Builder sqlSchemaBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [SqliteSchemaGenerator()],
    'sql_schema',
  );
}

Builder standaloneSqlSchemaBuilder(BuilderOptions options) {
  return LibraryBuilder(
    SqliteSchemaGenerator(),
    generatedExtension: '.sql.g.dart',
  );
}
