import 'sql_type.dart';

/// SQLite-specific SQL types and helpers.
///
/// SQLite uses dynamic typing with five storage classes (NULL, INTEGER, REAL,
/// TEXT, BLOB) and type affinity. The cross-dialect storage types (TEXT,
/// INTEGER, REAL, BLOB) live in [common_types.dart]; this file holds what is
/// only meaningful for SQLite.

/// NUMERIC affinity type (SQLite).
class NUMERIC extends SqlType {
  const NUMERIC();
}

// TODO(sqlite): add affinity helpers / pragma-driven types as needed.

/// SQLite collation sequences.
class Collate {
  /// Case-sensitive comparison (default).
  static const String binary = 'BINARY';

  /// Case-insensitive comparison.
  static const String noCase = 'NOCASE';

  /// Comparison ignoring trailing whitespace.
  static const String rtrim = 'RTRIM';

  // coverage:ignore-start
  Collate._();
  // coverage:ignore-end
}
