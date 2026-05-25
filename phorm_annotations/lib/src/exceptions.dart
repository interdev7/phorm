/// Exception thrown when a Dart-side validation fails.
class SqflowCHECKValidatorException implements Exception {
  final String table;
  final String column;
  final String message;
  final String? constraint;

  SqflowCHECKValidatorException({
    required this.table,
    required this.column,
    required this.message,
    this.constraint,
  });

  @override
  String toString() =>
      'SqflowCHECKValidatorException: [$table.$column] $message${constraint != null ? ' (Constraint: $constraint)' : ''}';
}

/// Exception thrown when a Dart-side validation fails.
class SqflowJSONValidatorException implements Exception {
  final String table;
  final String column;
  final String message;
  final String? constraint;

  SqflowJSONValidatorException({
    required this.table,
    required this.column,
    required this.message,
    this.constraint,
  });

  @override
  String toString() =>
      'SqflowJSONValidatorException: [$table.$column] $message${constraint != null ? ' (Constraint: $constraint)' : ''}';
}
