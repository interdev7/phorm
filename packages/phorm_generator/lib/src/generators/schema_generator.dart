import 'package:phorm_annotations/phorm_annotations.dart';

import 'mysql/mysql_schema_generator.dart';
import 'postgres/postgres_schema_generator.dart';
import 'sqlite/sqlite_schema_generator.dart';

/// Strategy that encapsulates all DDL generation rules that differ between
/// database dialects (SQLite, Postgres, MySQL).
///
/// The top-level [PhormSchemaGenerator] delegates every dialect-specific
/// decision (type mapping, auto-increment keyword, timestamp handling, default
/// formatting, identifier quoting) to one of these per-dialect generators so
/// the core generation logic stays dialect-agnostic.
abstract class SchemaGenerator {
  const SchemaGenerator();

  /// Returns the concrete [SchemaGenerator] for the given annotation [kind].
  factory SchemaGenerator.fromKind(SqlDialectKind kind) {
    switch (kind) {
      case SqlDialectKind.sqlite:
        return const SqliteSchemaGenerator();
      case SqlDialectKind.postgres:
        return const PostgresSchemaGenerator();
      case SqlDialectKind.mysql:
        return const MysqlSchemaGenerator();
    }
  }

  /// Human-readable dialect name, used in generated comments/headers.
  String get name;

  /// Maps a resolved Dart [typeName] (e.g. `int`, `double`, `String`,
  /// `DateTime`, `Uint8List`, `bool`, `num`, `Duration`, `BigInt`, `Uri`, or an
  /// enum) to the dialect's SQL column type.
  ///
  /// [isEnum] is true when the field type is a Dart enum.
  String mapCoreType(String? typeName, {required bool isEnum});

  /// SQL column type used for the implicit `created_at` / `updated_at` /
  /// `deleted_at` timestamp columns.
  String timestampColumnType();

  /// Inline clause appended to an auto-incrementing primary key column
  /// (e.g. ` AUTOINCREMENT` for SQLite). Empty if not applicable.
  String autoIncrementClause();

  /// Whether an integer primary key of [sqlType] becomes a self-managing
  /// auto-key inline (so NOT NULL / UNIQUE constraints should be skipped).
  bool isAutoPkInline(String sqlType);

  /// Formats a boolean default literal for this dialect.
  String formatBoolDefault(bool value);

  /// DDL emitted to keep `updated_at` current on UPDATE.
  ///
  /// SQLite returns a trigger; other dialects may return their own mechanism
  /// or `null` when the behaviour is handled inline on the column.
  String? updatedAtTimestampDdl(String tableName);

  /// Quotes an identifier (table/column). No-op for dialects that don't quote.
  String quoteIdentifier(String name);
}
