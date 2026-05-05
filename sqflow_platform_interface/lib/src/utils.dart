import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

/// Checks if a value is a valid email address.
class CheckEmail extends ICHECK {
  @override
  final String? constraint;

  const CheckEmail({this.constraint});

  @override
  String toSql(String columnName) => '';

  @override
  bool isValid(dynamic value) {
    return RegExp(
            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$")
        .hasMatch(value.toString());
  }
}

/// URL validation check.
class CheckURL extends ICHECK {
  @override
  final String? constraint;

  const CheckURL({this.constraint});

  @override
  String toSql(String columnName) => '';

  @override
  bool isValid(dynamic value) {
    return Uri.tryParse(value.toString()) != null;
  }
}
