import 'package:phorm_annotations/phorm_annotations.dart';

/// A typed representation of an SQL function call on a column.
/// Kept in sqflow_core because where_builder.dart needs it for column validation.
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
  static SqflowColumn<R> apply<T, R>(String functionName, SqflowColumn<T> col) {
    return SqlFunctionColumn<R>(functionName, col);
  }
}

/// Extension to allow applying any custom SQL function directly on any column in a type-safe way.
extension SqlFunctionExtension<T> on SqflowColumn<T> {
  /// Applies a custom SQL function to this column and returns a typed column of type [R].
  SqflowColumn<R> sqlFunction<R>(String functionName) {
    return SqlFunctionColumn<R>(functionName, this);
  }
}
