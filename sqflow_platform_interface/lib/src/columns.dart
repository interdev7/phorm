/// A typed representation of a database column.
/// Used for building type-safe queries.
class SqflowColumn<T> {
  /// The name of the column as it exists in the database.
  final String name;

  const SqflowColumn(this.name);

  @override
  String toString() => name;
}

/// Extensions for [SqflowColumn] to enable fluent query building.
extension SqflowColumnExtension<T> on SqflowColumn<T> {
  /// Creates an equality condition: `column = value`
  SqflowCondition eq(T value) => SqflowCondition(this, '=', value);

  /// Creates an inequality condition: `column != value`
  SqflowCondition ne(T value) => SqflowCondition(this, '!=', value);

  /// Creates a greater-than condition: `column > value`
  SqflowCondition gt(T value) => SqflowCondition(this, '>', value);

  /// Creates a greater-than-or-equal condition: `column >= value`
  SqflowCondition gte(T value) => SqflowCondition(this, '>=', value);

  /// Creates a less-than condition: `column < value`
  SqflowCondition lt(T value) => SqflowCondition(this, '<', value);

  /// Creates a less-than-or-equal condition: `column <= value`
  SqflowCondition lte(T value) => SqflowCondition(this, '<=', value);

  /// Creates a LIKE condition: `column LIKE pattern`
  SqflowCondition like(String pattern) =>
      SqflowCondition(this, 'LIKE', pattern);

  /// Creates a NOT LIKE condition: `column NOT LIKE pattern`
  SqflowCondition notLike(String pattern) =>
      SqflowCondition(this, 'NOT LIKE', pattern);

  /// Creates a case-insensitive LIKE condition: `LOWER(column) LIKE LOWER(pattern)`
  SqflowCondition ilike(String pattern) =>
      SqflowCondition(this, 'ILIKE', pattern);

  /// Creates a case-insensitive NOT LIKE condition: `LOWER(column) NOT LIKE LOWER(pattern)`
  SqflowCondition notIlike(String pattern) =>
      SqflowCondition(this, 'NOT ILIKE', pattern);

  /// Creates a REGEXP condition: `column REGEXP pattern`
  SqflowCondition regexp(String pattern) =>
      SqflowCondition(this, 'REGEXP', pattern);

  /// Creates an IN condition: `column IN (value1, value2, ...)`
  SqflowCondition inList(List<T> values) => SqflowCondition(this, 'IN', values);

  /// Creates a NOT IN condition: `column NOT IN (value1, value2, ...)`
  SqflowCondition notInList(List<T> values) =>
      SqflowCondition(this, 'NOT IN', values);

  /// Creates a BETWEEN condition: `column BETWEEN from AND to`
  SqflowCondition between(T from, T to) =>
      SqflowCondition(this, 'BETWEEN', [from, to]);

  /// Creates a NOT BETWEEN condition: `column NOT BETWEEN from AND to`
  SqflowCondition notBetween(T from, T to) =>
      SqflowCondition(this, 'NOT BETWEEN', [from, to]);

  /// Creates a STARTS WITH condition (sugar for LIKE 'pattern%')
  SqflowCondition startsWith(String pattern) =>
      SqflowCondition(this, 'STARTS WITH', pattern);

  /// Creates an ENDS WITH condition (sugar for LIKE '%pattern')
  SqflowCondition endsWith(String pattern) =>
      SqflowCondition(this, 'ENDS WITH', pattern);

  /// Creates an IS NULL condition.
  SqflowCondition isNull() => SqflowCondition(this, 'IS NULL', null);

  /// Creates an IS NOT NULL condition.
  SqflowCondition isNotNull() => SqflowCondition(this, 'IS NOT NULL', null);

  /// Creates a TRUE condition: `column = 1`
  SqflowCondition isTrue() => SqflowCondition(this, 'TRUE', null);

  /// Creates a FALSE condition: `column = 0`
  SqflowCondition isFalse() => SqflowCondition(this, 'FALSE', null);

  // =======================================================
  // STRING FUNCTIONS
  // =======================================================

  /// Creates a condition on the length of a column: `LENGTH(column) = ?`
  SqflowCondition lengthEq(int length) =>
      SqflowCondition(this, 'LENGTH =', length);

  /// Creates a condition on the length of a column: `LENGTH(column) != ?`
  SqflowCondition lengthNe(int length) =>
      SqflowCondition(this, 'LENGTH !=', length);

  /// Creates a condition on the length of a column: `LENGTH(column) > ?`
  SqflowCondition lengthGt(int length) =>
      SqflowCondition(this, 'LENGTH >', length);

  /// Creates a condition on the length of a column: `LENGTH(column) >= ?`
  SqflowCondition lengthGte(int length) =>
      SqflowCondition(this, 'LENGTH >=', length);

  /// Creates a condition on the length of a column: `LENGTH(column) < ?`
  SqflowCondition lengthLt(int length) =>
      SqflowCondition(this, 'LENGTH <', length);

  /// Creates a condition on the length of a column: `LENGTH(column) <= ?`
  SqflowCondition lengthLte(int length) =>
      SqflowCondition(this, 'LENGTH <=', length);

  /// Creates a SUBSTR equality: `SUBSTR(column, start, len) = ?`
  SqflowCondition substrEq(int start, int len, String value) =>
      SqflowCondition(this, 'SUBSTR =', [start, len, value]);

  /// Creates a SUBSTR LIKE condition: `SUBSTR(column, start, len) LIKE ?`
  SqflowCondition substrLike(int start, int len, String pattern) =>
      SqflowCondition(this, 'SUBSTR LIKE', [start, len, pattern]);

  /// Creates a case-insensitive SUBSTR LIKE: `LOWER(SUBSTR(column, start, len)) LIKE LOWER(?)`
  SqflowCondition substrIlike(int start, int len, String pattern) =>
      SqflowCondition(this, 'SUBSTR ILIKE', [start, len, pattern]);

  // =======================================================
  // DATE/TIME FUNCTIONS
  // =======================================================

  /// Creates a date-only equality: `DATE(column) = ?`
  SqflowCondition dateOnlyEq(DateTime date) =>
      SqflowCondition(this, 'DATE =', date);

  /// Creates a date-only greater-than: `DATE(column) > ?`
  SqflowCondition dateOnlyGt(DateTime date) =>
      SqflowCondition(this, 'DATE >', date);

  /// Creates a date-only less-than: `DATE(column) < ?`
  SqflowCondition dateOnlyLt(DateTime date) =>
      SqflowCondition(this, 'DATE <', date);

  /// Creates a date-only between range: `DATE(column) BETWEEN ? AND ?`
  SqflowCondition dateOnlyBetween(DateTime from, DateTime to) =>
      SqflowCondition(this, 'DATE BETWEEN', [from, to]);

  /// Creates a time-only equality: `TIME(column) = ?`
  SqflowCondition timeOnlyEq(DateTime time) =>
      SqflowCondition(this, 'TIME =', time);
}

/// Represents a single SQL condition built from a column and an operator.
class SqflowCondition {
  final SqflowColumn<dynamic> column;
  final String operator;
  final dynamic value;

  SqflowCondition(this.column, this.operator, this.value);
}
