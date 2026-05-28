/// Abstract interface/class representing all SQL-compatible database data types.
abstract class SqlType {
  const SqlType();
}

/// VARCHAR type with customizable length.
class VARCHAR extends SqlType {
  final int length;
  const VARCHAR(this.length);
}

/// TEXT type.
class TEXT extends SqlType {
  const TEXT();
}

/// INTEGER type (e.g. 32-bit integer).
class INTEGER extends SqlType {
  const INTEGER();
}

/// BIGINT type (e.g. 64-bit integer).
class BIGINT extends SqlType {
  const BIGINT();
}

/// BOOLEAN type.
class BOOLEAN extends SqlType {
  const BOOLEAN();
}

/// REAL type.
class REAL extends SqlType {
  const REAL();
}

/// DOUBLE precision floating point type.
class DOUBLE extends SqlType {
  const DOUBLE();
}

/// DECIMAL type with custom precision and scale.
class DECIMAL extends SqlType {
  final int precision;
  final int scale;
  const DECIMAL(this.precision, this.scale);
}

/// DATE type.
class DATE extends SqlType {
  const DATE();
}

/// TIME type.
class TIME extends SqlType {
  const TIME();
}

/// TIMESTAMP / DATETIME type.
class TIMESTAMP extends SqlType {
  const TIMESTAMP();
}

/// JSON type.
class JSON extends SqlType {
  const JSON();
}

/// JSONB binary JSON type (highly useful for Postgres).
class JSONB extends SqlType {
  const JSONB();
}

/// BLOB binary large object type.
class BLOB extends SqlType {
  const BLOB();
}

/// Standard SQLite data types (deprecated, use [SqlType] hierarchy instead).
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
