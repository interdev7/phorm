part of 'where_builder.dart';

// =======================================================
// WHERE CONDITIONS (internal representation)
// =======================================================

/// Marker inserted into condition templates where the (dialect-escaped)
/// column expression belongs. The NUL bytes cannot appear in validated
/// column names or SQL keywords, so no substring clash is possible.
const String _colToken = '\u0000col\u0000';

/// Replaces positional `?` placeholders with dialect-specific ones,
/// advancing [paramIndex] once per placeholder.
String _compilePlaceholders(
  String sql,
  SqlDialect dialect,
  ParamIndex paramIndex,
) {
  if (!sql.contains('?')) return sql;

  final testPlaceholder = dialect.compilePlaceholder(paramIndex.value);
  if (testPlaceholder == '?') {
    // SQLite/MySQL case: placeholder is '?'. Just count how many '?' are in the sql and advance paramIndex
    final count = '?'.allMatches(sql).length;
    paramIndex.value += count;
    return sql;
  }

  var result = sql;
  while (result.contains('?')) {
    final placeholder = dialect.compilePlaceholder(paramIndex.value++);
    result = result.replaceFirst('?', placeholder);
  }
  return result;
}

/// Internal representation of a single WHERE clause entry.
sealed class _Condition {
  List<Object?> get args;

  String compile(SqlDialect dialect, ParamIndex paramIndex);
}

/// A condition built from a known column: the column is stored separately
/// from the SQL [template] (which references it via [_colToken]) and is
/// escaped structurally by the dialect — no string matching involved.
class _ColumnCondition implements _Condition {
  _ColumnCondition(this.column, this.template, this.args);

  /// String column name, or a [SqlFunctionColumn] wrapping one.
  final Object column;
  final String template;
  @override
  final List<Object?> args;

  static String _escapeColumn(Object column, SqlDialect dialect) {
    if (column is SqlFunctionColumn) {
      return '${column.functionName}'
          '(${_escapeColumn(column.innerColumn, dialect)})';
    }
    return dialect.escapeIdentifier(column.toString());
  }

  @override
  String compile(SqlDialect dialect, ParamIndex paramIndex) {
    final sql = template.replaceAll(_colToken, _escapeColumn(column, dialect));
    return _compilePlaceholders(sql, dialect, paramIndex);
  }
}

/// A raw SQL condition (escape hatch) — emitted verbatim, no column escaping.
class _RawCondition implements _Condition {
  _RawCondition(this.sql, this.args);

  final String sql;
  @override
  final List<Object?> args;

  @override
  String compile(SqlDialect dialect, ParamIndex paramIndex) {
    return _compilePlaceholders(sql, dialect, paramIndex);
  }
}

/// A nested AND/OR group.
class _GroupCondition implements _Condition {
  _GroupCondition(this.builder);

  final WhereBuilder builder;

  @override
  List<Object?> get args => builder.args;

  @override
  String compile(SqlDialect dialect, ParamIndex paramIndex) {
    final built = builder._buildWithDialect(dialect, paramIndex);
    if (built.isEmpty) return '';
    return builder._conditions.length > 1 ? '($built)' : built;
  }
}
