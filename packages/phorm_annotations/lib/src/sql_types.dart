// Barrel for SQL type definitions, organised by dialect.
//
// - sql_types/sql_type.dart — base SqlType.
// - sql_types/common_types.dart — types valid in every dialect.
// - sql_types/sqlite_types.dart — SQLite-specific types and Collate.
// - sql_types/postgres_types.dart — PostgreSQL-specific types.
// - sql_types/mysql_types.dart — MySQL / MariaDB-specific types.
export 'sql_types/common_types.dart';
export 'sql_types/mysql_types.dart';
export 'sql_types/postgres_types.dart';
export 'sql_types/sql_type.dart';
export 'sql_types/sqlite_types.dart';

/// Standard SQLite type-name string constants.
///
/// Prefer the typed `SqlType` hierarchy via `@Column(type: ...)` (e.g.
/// `TEXT()`, `INTEGER()`, `VARCHAR(255)`) — it is compile-time checked and
/// works across dialects. Use a raw `@Column(sqlType: '...')` string only for
/// DDL that has no `SqlType` class.
@Deprecated(
  'Use the SqlType hierarchy via @Column(type: ...) '
  '(or a raw @Column(sqlType: "...") string). Will be removed in a future release.',
)
class SqlTypes {
  /// TEXT data type.
  static const String text = 'TEXT';

  /// INTEGER data type.
  static const String integer = 'INTEGER';

  /// REAL data type.
  static const String real = 'REAL';

  /// BLOB data type.
  static const String blob = 'BLOB';

  /// NUMERIC data type.
  static const String numeric = 'NUMERIC';

  /// Private constructor to prevent instantiation.
  // coverage:ignore-start
  @Deprecated('Use the SqlType hierarchy via @Column(type: ...).')
  SqlTypes._();
  // coverage:ignore-end
}
