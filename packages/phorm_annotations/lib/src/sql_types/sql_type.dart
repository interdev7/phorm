/// Abstract interface/class representing all SQL-compatible database data types.
///
/// Concrete types are organised by dialect:
/// - [common_types.dart] — types available across SQLite, Postgres and MySQL.
/// - [sqlite_types.dart] — SQLite-specific types and helpers.
/// - [postgres_types.dart] — PostgreSQL-specific types.
/// - [mysql_types.dart] — MySQL / MariaDB-specific types.
abstract class SqlType {
  const SqlType();
}
