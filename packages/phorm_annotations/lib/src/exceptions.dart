/// Exception thrown when a Dart-side validation fails.
class PhormCHECKValidatorException implements Exception {
  /// The table the failed constraint belongs to.
  final String table;

  /// The column the failed constraint belongs to.
  final String column;

  /// Human-readable validation failure message.
  final String message;

  /// The named constraint that failed, if any.
  final String? constraint;

  /// Creates the exception with failure details.
  PhormCHECKValidatorException({
    required this.table,
    required this.column,
    required this.message,
    this.constraint,
  });

  @override
  String toString() =>
      'PhormCHECKValidatorException: [$table.$column] $message${constraint != null ? ' (Constraint: $constraint)' : ''}';
}

/// Exception thrown when a Dart-side validation fails.
class PhormJSONValidatorException implements Exception {
  /// The table the failed constraint belongs to.
  final String table;

  /// The column the failed constraint belongs to.
  final String column;

  /// Human-readable validation failure message.
  final String message;

  /// The named constraint that failed, if any.
  final String? constraint;

  /// Creates the exception with failure details.
  PhormJSONValidatorException({
    required this.table,
    required this.column,
    required this.message,
    this.constraint,
  });

  @override
  String toString() =>
      'PhormJSONValidatorException: [$table.$column] $message${constraint != null ? ' (Constraint: $constraint)' : ''}';
}
