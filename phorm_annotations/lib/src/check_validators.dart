import '../phorm_annotations.dart';

class NotContainsValidator implements ICheckValidator {
  final ICheckValidator condition;
  @override
  final String? constraint;
  const NotContainsValidator(this.condition, {this.constraint});
  @override
  String toSql(String columnName) => 'NOT (${condition.toSql(columnName)})';

  @override
  bool isValid(dynamic value) => !condition.isValid(value);
}

class LengthValidator implements ICheckValidator {
  final int? min;
  final int? max;
  @override
  final String? constraint;
  const LengthValidator({this.min, this.max, this.constraint});
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

class NotEmptyValidator implements ICheckValidator {
  @override
  final String? constraint;
  const NotEmptyValidator({this.constraint});
  @override
  String toSql(String columnName) => '$columnName <> ""';

  @override
  bool isValid(dynamic value) => value != null && value.toString().isNotEmpty;
}

class ContainsValidator implements ICheckValidator {
  final List<dynamic> values;
  @override
  final String? constraint;

  const ContainsValidator(this.values, {this.constraint});

  @override
  String toSql(String columnName) {
    final formattedValues =
        values.map((v) => v is String ? "'$v'" : v.toString()).join(', ');
    return '$columnName IN ($formattedValues)';
  }

  @override
  bool isValid(dynamic value) => values.contains(value);
}

class RangeValidator implements ICheckValidator {
  final num? min;
  final num? max;
  @override
  final String? constraint;

  const RangeValidator({this.min, this.max, this.constraint});

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

class ComparisonValidator implements ICheckValidator {
  final num value;
  final String operator;
  @override
  final String? constraint;

  const ComparisonValidator(this.value, this.operator, {this.constraint});

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

class CustomSqlValidator implements ICheckValidator {
  final String sql;
  @override
  final String? constraint;

  const CustomSqlValidator(this.sql, {this.constraint});

  @override
  String toSql(String columnName) {
    if (sql.contains('{column}')) {
      return sql.replaceAll('{column}', columnName);
    }
    return sql;
  }

  @override
  bool isValid(dynamic value) {
    return true; // Dart-side execution is ignored for pure SQL custom checks
  }
}
