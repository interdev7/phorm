import 'package:analyzer/dart/element/element.dart';
import 'package:phorm_annotations/phorm_annotations.dart';

import 'mysql/mysql_function_generator.dart';
import 'postgres/postgres_function_generator.dart';
import 'sqlite/sqlite_function_generator.dart';

/// Parsed representation of a Dart function annotated with [SqlFunc].
class SqlFuncData {
  /// The annotated Dart function element.
  final TopLevelFunctionElement element;

  /// The resolved SQL-native name of the function.
  final String sqlName;

  const SqlFuncData({required this.element, required this.sqlName});
}

/// Strategy that emits the dialect-specific code/DDL for custom SQL functions.
///
/// Each dialect has its own function syntax (SQLite registers native callbacks,
/// Postgres/MySQL emit `CREATE FUNCTION` DDL), so the emission is delegated to a
/// per-dialect implementation. Parsing of the annotated elements is shared and
/// lives in the top-level `PhormFunctionGenerator`.
abstract class FunctionGenerator {
  const FunctionGenerator();

  /// Returns the concrete [FunctionGenerator] for the given annotation [kind].
  factory FunctionGenerator.fromKind(SqlDialectKind kind) {
    switch (kind) {
      case SqlDialectKind.sqlite:
        return const SqliteFunctionGenerator();
      case SqlDialectKind.postgres:
        return const PostgresFunctionGenerator();
      case SqlDialectKind.mysql:
        return const MysqlFunctionGenerator();
    }
  }

  /// Human-readable dialect name.
  String get name;

  /// Emits the body (everything after the `part of` header) for the given
  /// [functions]. Returns an empty string if nothing should be generated.
  String generate(List<SqlFuncData> functions);
}
