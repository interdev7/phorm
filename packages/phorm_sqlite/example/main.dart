// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm_sqlite/phorm_sqlite.dart';

void main() {
  // Create a SQLite-backed PHORM database handle. Register your generated
  // tables in `tables` and call `db.database` to open and run migrations.
  final db = DB(
    databaseName: ':memory:',
    version: 1,
    tables: const [],
  );

  // The SQLite dialect decides how identifiers and placeholders are compiled.
  final dialect = SqliteDialect();
  print('Database created: $db');
  print('Placeholder for arg 1: ${dialect.compilePlaceholder(1)}');
}
