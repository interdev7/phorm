/// Standard SQLite data types.
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
  SqlTypes._();
}

/// SQLite collation sequences.
class Collate {
  /// Case-sensitive comparison (default).
  static const String binary = 'BINARY';

  /// Case-insensitive comparison.
  static const String noCase = 'NOCASE';

  /// Comparison ignoring trailing whitespace.
  static const String rtrim = 'RTRIM';

  Collate._();
}
