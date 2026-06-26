import 'sql_type.dart';

/// SQL data types available across all supported dialects
/// (SQLite, PostgreSQL, MySQL / MariaDB).
///
/// Dialect-specific types live in their own files:
/// [sqlite_types.dart], [postgres_types.dart], [mysql_types.dart].

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

/// BLOB binary large object type.
class BLOB extends SqlType {
  const BLOB();
}
