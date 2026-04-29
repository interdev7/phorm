import 'data_type.dart';

/// Integer data type.
///
/// Example: `INTEGER()`
///
/// Used to store integer data.
///
/// In SQLite, INTEGER columns can store any value that can be expressed
/// as an integer.
class INTEGER extends DataType {
  const INTEGER();
}

/// Text data type.
///
/// Example: `TEXT()`
///
/// Used to store text data.
///
/// In SQLite, TEXT columns can store any value that can be expressed
/// as a text string.
class TEXT extends DataType {
  const TEXT();
}

/// Blob data type.
///
/// Example: `BLOB()`
///
/// Used to store binary data.
///
/// In SQLite, BLOB columns can store any value that can be expressed
/// as a binary data.
class BLOB extends DataType {
  const BLOB();
}

/// Real data type.
///
/// Example: `REAL()`
///
/// Used to store real numbers.
///
/// In SQLite, REAL columns can store any value that can be expressed
/// as a floating-point number.
class REAL extends DataType {
  const REAL();
}

/// Numeric data type.
///
/// Example: `NUMERIC()`
///
/// Used to store numeric data.
///
/// In SQLite, NUMERIC columns can store any value that can be expressed
/// as a floating-point number, integer, or text string that can be interpreted as a number.
class NUMERIC extends DataType {
  const NUMERIC();
}
