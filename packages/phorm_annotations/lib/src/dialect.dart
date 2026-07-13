/// Parameter index holder to track sequential placeholders during SQL compilation.
class ParamIndex {
  /// The next placeholder index (1-based).
  int value = 1;
}

/// Interface defining SQL syntax generation rules for a specific database dialect.
abstract class SqlDialect {
  /// Escapes identifiers such as tables or column names.
  ///
  /// SQLite/Postgres: `"table"."column"`
  /// MySQL: `` `table`.`column` ``
  String escapeIdentifier(String name);

  /// Generates the SQL query positional placeholder.
  ///
  /// SQLite/MySQL: `?`
  /// Postgres: `\$1`, `\$2`, etc.
  String compilePlaceholder(int index);

  /// Compiles a JSON object expression from key-value fields.
  /// KeyValues maps column keys to their database column expressions (e.g. `'id' => 'users.id'`).
  ///
  /// SQLite: `json_object('key1', val1, 'key2', val2)`
  /// Postgres: `jsonb_build_object('key1', val1, 'key2', val2)`
  String compileJsonObject(Map<String, String> keyValues);

  /// Compiles a JSON array aggregation from a JSON object expression and FROM/WHERE clause.
  ///
  /// SQLite: `(SELECT json_group_array(jsonObjectExpr) fromAndWhereClause)`
  /// Postgres: `coalesce((SELECT jsonb_agg(jsonObjectExpr) fromAndWhereClause), '[]'::jsonb)`
  String compileJsonArray(String jsonObjectExpr, String fromAndWhereClause);
}

/// Default dialect that does not escape identifiers and uses positional '?' placeholders.
class NoEscapeDialect implements SqlDialect {
  /// Creates the pass-through dialect.
  const NoEscapeDialect();

  @override
  String escapeIdentifier(String name) => name;

  @override
  String compilePlaceholder(int index) => '?';

  @override
  String compileJsonObject(Map<String, String> keyValues) {
    if (keyValues.isEmpty) return 'json_object()';
    final parts = keyValues.entries
        .map((e) => "'${e.key}', ${e.value}")
        .join(', ');
    return 'json_object($parts)';
  }

  @override
  String compileJsonArray(String jsonObjectExpr, String fromAndWhereClause) {
    return '(SELECT json_group_array($jsonObjectExpr) $fromAndWhereClause)';
  }
}
