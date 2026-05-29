import 'package:phorm/phorm.dart';

/// SQLite implementation of the SqlDialect interface.
class SqliteDialect implements SqlDialect {
  @override
  String escapeIdentifier(String name) {
    if (name.contains('.')) {
      return name.split('.').map((part) => '"$part"').join('.');
    }
    return '"$name"';
  }

  @override
  String compilePlaceholder(int index) {
    return '?';
  }

  @override
  String compileJsonObject(Map<String, String> keyValues) {
    if (keyValues.isEmpty) return 'json_object()';
    final parts =
        keyValues.entries.map((e) => "'${e.key}', ${e.value}").join(', ');
    return 'json_object($parts)';
  }

  @override
  String compileJsonArray(String jsonObjectExpr, String fromAndWhereClause) {
    return '(SELECT json_group_array($jsonObjectExpr) $fromAndWhereClause)';
  }
}
