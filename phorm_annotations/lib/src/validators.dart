abstract interface class ISQLValidator {
  /// Generates SQL expression for the condition.
  /// [columnName] - the column name to which the condition is applied.
  String toSql(String columnName);
}

/// Base interface for check conditions (CHECK constraints).
abstract interface class IValidator {
  const IValidator();

  /// Optional constraint name (CONSTRAINT name for CHECK constraint or error name for JSON validation).
  String? get constraint;

  /// Validates the [value] in Dart.
  /// Returns true if valid, false otherwise.
  bool isValid(dynamic value);
}

/// JSON validation check (No SQL generation).
abstract interface class IJsonValidator implements IValidator {}

/// CHECK constraint validation check (SQL generation).
abstract interface class ICheckValidator implements ISQLValidator, IValidator {}

class RegExpValidator implements IJsonValidator {
  final String pattern;
  @override
  final String? constraint;

  const RegExpValidator(this.pattern, {this.constraint});

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    return RegExp(pattern).hasMatch(value.toString());
  }
}

/// Checks if a value is a valid email address.
class EmailValidator implements IJsonValidator {
  @override
  final String? constraint;

  const EmailValidator({this.constraint});

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    return RegExp(
            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$")
        .hasMatch(value.toString());
  }
}

/// URL validation check.
class URLValidator implements IJsonValidator {
  @override
  final String? constraint;

  const URLValidator({this.constraint});

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    return Uri.tryParse(value.toString()) != null;
  }
}
