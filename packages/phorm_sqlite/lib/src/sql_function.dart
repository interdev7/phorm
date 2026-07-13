// SqlFunction — custom SQL function registration for SQLite databases.

/// Represents a custom SQL function that can be registered with the database.
///
/// Custom functions allow you to extend SQLite with Dart logic that can be
/// called from SQL queries.
///
/// **Example:**
/// ```dart
/// final regexpFunction = SqlFunction(
///   name: 'REGEXP',
///   argumentCount: 2,
///   function: (args) {
///     final pattern = args[0] as String;
///     final text = args[1] as String;
///     return RegExp(pattern).hasMatch(text) ? 1 : 0;
///   },
/// );
/// ```
class SqlFunction {
  /// The name of the function as it will be called in SQL
  final String name;

  /// The number of arguments the function accepts
  /// Use -1 for variable number of arguments
  final int argumentCount;

  /// The Dart function that implements the SQL function logic
  ///
  /// Takes a list of arguments and returns the result.
  /// Return types should be SQLite-compatible: int, double, String, Uint8List, or null
  final Object? Function(List<Object?>) function;

  /// Whether the function is deterministic (always returns same result for same inputs)
  ///
  /// Deterministic functions can be optimized by SQLite.
  /// Set to true if your function has no side effects and always returns
  /// the same result for the same inputs.
  final bool deterministic;

  const SqlFunction({
    required this.name,
    required this.argumentCount,
    required this.function,
    this.deterministic = true,
  });

  /// Creates a REGEXP function for pattern matching
  ///
  /// **Usage in SQL:**
  /// ```sql
  /// SELECT * FROM users WHERE email REGEXP '.*@gmail\.com'
  /// ```
  factory SqlFunction.regexp() {
    return SqlFunction(
      name: 'REGEXP',
      argumentCount: 2,
      function: (args) {
        if (args[0] == null || args[1] == null) return 0;
        final pattern = args[0].toString();
        final text = args[1].toString();
        try {
          return RegExp(pattern).hasMatch(text) ? 1 : 0;
        } on Object {
          return 0;
        }
      },
    );
  }

  /// Creates a custom string function
  ///
  /// **Example:**
  /// ```dart
  /// final reverse = SqlFunction.custom(
  ///   name: 'REVERSE',
  ///   argumentCount: 1,
  ///   function: (args) => args[0].toString().split('').reversed.join(),
  /// );
  /// ```
  factory SqlFunction.custom({
    required String name,
    required int argumentCount,
    required Object? Function(List<Object?>) function,
    bool deterministic = true,
  }) {
    return SqlFunction(
      name: name,
      argumentCount: argumentCount,
      function: function,
      deterministic: deterministic,
    );
  }
}

/// A typed representation of an SQL function call on a column.
/// Re-exported from `phorm` — do not redeclare here.
// SqlFunctionColumn, SqlFunctions, SqlFunctionExtension are in `phorm`.
