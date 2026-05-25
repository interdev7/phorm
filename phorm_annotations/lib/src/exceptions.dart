/// Exception thrown when a Dart-side validation fails.
class PhormCHECKValidatorException implements Exception {
  final String table;
  final String column;
  final String message;
  final String? constraint;

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
  final String table;
  final String column;
  final String message;
  final String? constraint;

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
