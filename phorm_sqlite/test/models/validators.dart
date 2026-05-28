import 'package:phorm_sqlite/phorm_sqlite.dart';

class LengthValidator implements ISqlValidator, IJsonValidator {
  final int? min;
  final int? max;
  @override
  final String? constraint;

  // sql must be a final field (not a getter) so that the code generator
  // can read it via ConstantReader at build time.
  // Ternary operators are valid const expressions in Dart.
  @override
  final String sql;

  const LengthValidator({int? min, int? max, this.constraint})
      : min = min,
        max = max,
        sql = (min != null && max != null)
            ? 'LENGTH({column}) BETWEEN $min AND $max'
            : (min != null)
                ? 'LENGTH({column}) >= $min'
                : (max != null)
                    ? 'LENGTH({column}) <= $max'
                    : '';

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    final len = value.toString().length;
    if (min != null && len < min!) return false;
    if (max != null && len > max!) return false;
    return true;
  }
}

class NotEmptyValidator implements ISqlValidator, IJsonValidator {
  @override
  final String? constraint;

  // Use a final field so the code generator can read it at build time.
  // Single quotes are correct SQL string delimiters.
  @override
  final String sql;

  const NotEmptyValidator({this.constraint}) : sql = "{column} <> ''";

  @override
  bool isValid(dynamic value) => value != null && value.toString().isNotEmpty;
}

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

class ContainsValidator implements ISqlValidator, IJsonValidator {
  final List<dynamic> values;
  @override
  final String? constraint;

  const ContainsValidator(this.values, {this.constraint});

  // ContainsValidator.sql is a computed getter because List.map().join()
  // is not a const expression. The code generator handles this via a
  // fallback that reads the `values` field directly from the DartObject.
  @override
  String get sql {
    final formatted =
        values.map((v) => v is String ? "'$v'" : v.toString()).join(', ');
    return '{column} IN ($formatted)';
  }

  @override
  bool isValid(dynamic value) => values.contains(value);
}

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

class IsNumberValidator implements IJsonValidator {
  @override
  final String? constraint;

  const IsNumberValidator({this.constraint});

  @override
  bool isValid(dynamic value) {
    if (value == null) return true;
    return num.tryParse(value.toString()) != null;
  }
}
