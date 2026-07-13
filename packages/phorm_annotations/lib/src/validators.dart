/// Base interface for check conditions (CHECK constraints).
abstract class IValidator {
  /// Const base constructor.
  const IValidator();

  /// Optional constraint name (CONSTRAINT name for CHECK constraint or error name for JSON validation).
  String? get constraint;
}

/// JSON validation check (No SQL generation).
abstract class IJsonValidator implements IValidator {
  /// Const base constructor.
  const IJsonValidator();

  /// Validates the [value] in Dart.
  /// Returns true if valid, false otherwise.
  bool isValid(dynamic value);
}

/// CHECK constraint validation check (SQL generation).
///
/// **IMPORTANT for implementors**: The [sql] property MUST be declared as a
/// `final String sql` field (not a computed getter) so that the code generator
/// can read it via Dart's constant evaluation at build time.
///
/// ✅ Correct — final field, readable at generation time:
/// ```dart
/// class MyValidator implements ISqlValidator {
///   @override
///   final String sql;
///   const MyValidator() : sql = '{column} IS NOT NULL';
/// }
/// ```
///
/// ✅ Also correct for parameterized validators (ternary is a const expression):
/// ```dart
/// class RangeValidator implements ISqlValidator {
///   @override
///   final String sql;
///   const RangeValidator(int min, int max)
///     : sql = '{column} BETWEEN $min AND $max';
/// }
/// ```
///
/// ❌ Wrong — computed getter cannot be read by the generator:
/// ```dart
/// @override
/// String get sql { // will NOT generate a CHECK constraint
///   if (someCondition) return '...';
///   return '...';
/// }
/// ```
///
/// For validators whose SQL depends on a list of values and cannot be
/// expressed as a const expression (e.g., `IN (...)` clauses), the
/// generator will automatically fall back to reading the `values` field
/// and constructing the IN clause.
abstract class ISqlValidator implements IValidator {
  /// Const base constructor.
  const ISqlValidator();

  /// The SQL template expression. Can contain `{column}` as a placeholder.
  ///
  /// Must be implemented as a `final String sql` field for code generation
  /// to be able to emit a CHECK constraint in the database schema.
  String get sql;
}

/// Generic SQL validator that accepts a raw SQL condition.
///
/// Use `{column}` as a placeholder for the column name.
/// Example: `CustomSqlValidator('{column} % 2 = 0', constraint: 'even_check')`
class CustomSqlValidator implements ISqlValidator {
  @override
  final String sql;

  @override
  final String? constraint;

  /// Creates a validator from a raw SQL [sql] expression.
  const CustomSqlValidator(this.sql, {this.constraint});
}
