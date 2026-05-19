import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

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
///
/// // Use in DB initialization
/// final db = DB(
///   databaseName: 'app.db',
///   version: 1,
///   tables: [usersTable],
///   customFunctions: [regexpFunction],
/// );
///
/// // Use in queries
/// final users = await Users.where(
///   WhereBuilder().custom('REGEXP(?, email)', ['.*@gmail\\.com'])
/// ).get();
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
        } catch (e) {
          return 0;
        }
      },
      deterministic: true,
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
class SqlFunctionColumn<T> extends SqflowColumn<T> {
  /// The name of the SQL function.
  final String functionName;

  /// The column the function is applied to.
  final SqflowColumn<dynamic> innerColumn;

  const SqlFunctionColumn(this.functionName, this.innerColumn)
      : super('$functionName($innerColumn)');
}

/// Helper class to apply registered SQL functions to database columns in a type-safe way.
class SqlFunctions {
  /// Applies any SQL function to a column.
  ///
  /// **Example:**
  /// ```dart
  /// SqlFunctions.apply<int, int>('DOUBLE', Users.age)
  /// ```
  static SqflowColumn<R> apply<T, R>(String functionName, SqflowColumn<T> col) {
    return SqlFunctionColumn<R>(functionName, col);
  }
}

/// Extension to allow applying any custom SQL function directly on any column in a type-safe way.
extension SqlFunctionExtension<T> on SqflowColumn<T> {
  /// Applies a custom SQL function to this column and returns a typed column of type [R].
  ///
  /// **Example:**
  /// ```dart
  /// Users.age.sqlFunction<int>('MY_CUSTOM_FUNCTION')
  /// ```
  SqflowColumn<R> sqlFunction<R>(String functionName) {
    return SqlFunctionColumn<R>(functionName, this);
  }
}
