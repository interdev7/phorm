/// Base interface for check conditions (CHECK constraints).
abstract class ICHECK {
  const ICHECK();

  /// Generates SQL expression for the condition.
  /// [columnName] - the column name to which the condition is applied.
  String toSql(String columnName);

  /// Optional constraint name (CONSTRAINT name).
  String? get constraint;

  /// Validates the [value] in Dart.
  /// Returns true if valid, false otherwise.
  bool isValid(dynamic value);
}

/// Exception thrown when a Dart-side CHECK validation fails.
class SqflowCheckException implements Exception {
  final String table;
  final String column;
  final String message;
  final String? constraint;

  SqflowCheckException({
    required this.table,
    required this.column,
    required this.message,
    this.constraint,
  });

  @override
  String toString() =>
      'SqflowCheckException: [$table.$column] $message${constraint != null ? ' (Constraint: $constraint)' : ''}';
}

class CheckComposite extends ICHECK {
  final List<ICHECK> conditions;
  final String operator;
  @override
  final String? constraint;
  const CheckComposite(this.conditions, this.operator, {this.constraint});
  @override
  String toSql(String columnName) {
    if (conditions.isEmpty) return '';
    final parts =
        conditions.map((c) => '(${c.toSql(columnName)})').join(' $operator ');
    return parts;
  }

  @override
  bool isValid(dynamic value) {
    if (conditions.isEmpty) return true;
    if (operator == 'AND') {
      return conditions.every((c) => c.isValid(value));
    } else {
      return conditions.any((c) => c.isValid(value));
    }
  }
}

class CheckNot extends ICHECK {
  final ICHECK condition;
  @override
  final String? constraint;
  const CheckNot(this.condition, {this.constraint});
  @override
  String toSql(String columnName) => 'NOT (${condition.toSql(columnName)})';

  @override
  bool isValid(dynamic value) => !condition.isValid(value);
}

class CheckLength extends ICHECK {
  final int? min;
  final int? max;
  @override
  final String? constraint;
  const CheckLength({this.min, this.max, this.constraint});
  @override
  String toSql(String columnName) {
    final lengthExpr = 'LENGTH($columnName)';
    if (min != null && max != null) {
      return '$lengthExpr BETWEEN $min AND $max';
    } else if (min != null) {
      return '$lengthExpr >= $min';
    } else if (max != null) {
      return '$lengthExpr <= $max';
    }
    return '';
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    final len = value.toString().length;
    if (min != null && len < min!) return false;
    if (max != null && len > max!) return false;
    return true;
  }
}

class CheckInList extends ICHECK {
  final List<dynamic> values;
  @override
  final String? constraint;

  const CheckInList(this.values, {this.constraint});

  @override
  String toSql(String columnName) {
    final formattedValues =
        values.map((v) => v is String ? "'$v'" : v.toString()).join(', ');
    return '$columnName IN ($formattedValues)';
  }

  @override
  bool isValid(dynamic value) => values.contains(value);
}

class CheckRange extends ICHECK {
  final num? min;
  final num? max;
  @override
  final String? constraint;

  const CheckRange({this.min, this.max, this.constraint});

  @override
  String toSql(String columnName) {
    if (min != null && max != null) {
      return '$columnName BETWEEN $min AND $max';
    } else if (min != null) {
      return '$columnName >= $min';
    } else if (max != null) {
      return '$columnName <= $max';
    }
    return '';
  }

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    if (value is! num) return false;
    if (min != null && value < min!) return false;
    if (max != null && value > max!) return false;
    return true;
  }
}

class CheckComparison extends ICHECK {
  final num value;
  final String operator;
  @override
  final String? constraint;

  const CheckComparison(this.value, this.operator, {this.constraint});

  @override
  String toSql(String columnName) => '$columnName $operator $value';

  @override
  bool isValid(dynamic val) {
    if (val == null) return true;
    if (val is! num) return false;
    switch (operator) {
      case '>':
        return val > value;
      case '<':
        return val < value;
      case '>=':
        return val >= value;
      case '<=':
        return val <= value;
      case '=':
        return val == value;
      case '!=':
      case '<>':
        return val != value;
      default:
        return true;
    }
  }
}

class CheckRegExp extends ICHECK {
  final RegExp regex;
  @override
  final String? constraint;

  const CheckRegExp(this.regex, {this.constraint});

  @override
  String toSql(String columnName) {
    return '';
  }

  @override
  bool isValid(dynamic value) {
    return regex.hasMatch(value.toString());
  }
}

class CheckCustom extends ICHECK {
  final String sql;
  @override
  final String? constraint;

  const CheckCustom(this.sql, {this.constraint});

  @override
  String toSql(String columnName) {
    if (sql.contains('{column}')) {
      return sql.replaceAll('{column}', columnName);
    }
    return sql;
  }

  @override
  bool isValid(dynamic value) {
    return true;
  }
}
