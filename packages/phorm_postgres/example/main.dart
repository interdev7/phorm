// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm_postgres/phorm_postgres.dart';

// NOTE: the PostgreSQL driver is a work in progress and not yet functional.
// This example only demonstrates the dialect's SQL compilation rules.
void main() {
  final dialect = PostgresDialect();

  print('Escaped identifier: ${dialect.escapeIdentifier('users.id')}');
  print('Placeholder:        ${dialect.compilePlaceholder(1)}');
}
