// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm_mysql/phorm_mysql.dart';

// NOTE: the MySQL driver is a work in progress and not yet functional.
// This example only demonstrates the dialect's SQL compilation rules.
void main() {
  final dialect = MysqlDialect();

  print('Escaped identifier: ${dialect.escapeIdentifier('users.id')}');
  print('Placeholder:        ${dialect.compilePlaceholder(1)}');
}
