import 'sql_type.dart';

/// SQL data types available across all supported dialects
/// (SQLite, PostgreSQL, MySQL / MariaDB).
///
/// Dialect-specific types live in their own files:
/// `sqlite_types.dart`, `postgres_types.dart`, `mysql_types.dart`.

/// VARCHAR type with customizable length.
class VARCHAR extends SqlType {
  /// Maximum character length.
  final int length;

  /// Creates a VARCHAR of [length].
  const VARCHAR(this.length);
}

/// TEXT type.
class TEXT extends SqlType {
  /// Creates a TEXT type marker.
  const TEXT();
}

/// INTEGER type (e.g. 32-bit integer).
class INTEGER extends SqlType {
  /// Creates an INTEGER type marker.
  const INTEGER();
}

/// BIGINT type (e.g. 64-bit integer).
class BIGINT extends SqlType {
  /// Creates a BIGINT type marker.
  const BIGINT();
}

/// BOOLEAN type.
class BOOLEAN extends SqlType {
  /// Creates a BOOLEAN type marker.
  const BOOLEAN();
}

/// REAL type.
class REAL extends SqlType {
  /// Creates a REAL type marker.
  const REAL();
}

/// DOUBLE precision floating point type.
class DOUBLE extends SqlType {
  /// Creates a DOUBLE type marker.
  const DOUBLE();
}

/// DECIMAL type with custom precision and scale.
class DECIMAL extends SqlType {
  /// Total number of significant digits.
  final int precision;

  /// Digits after the decimal point.
  final int scale;

  /// Creates a DECIMAL([precision], [scale]) type.
  const DECIMAL(this.precision, this.scale);
}

/// DATE type.
class DATE extends SqlType {
  /// Creates a DATE type marker.
  const DATE();
}

/// TIME type.
class TIME extends SqlType {
  /// Creates a TIME type marker.
  const TIME();
}

/// TIMESTAMP / DATETIME type.
class TIMESTAMP extends SqlType {
  /// Creates a TIMESTAMP type marker.
  const TIMESTAMP();
}

/// JSON type.
class JSON extends SqlType {
  /// Creates a JSON type marker.
  const JSON();
}

/// BLOB binary large object type.
class BLOB extends SqlType {
  /// Creates a BLOB type marker.
  const BLOB();
}
