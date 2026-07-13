/// A typed representation of a database column.
/// Used for building type-safe queries.
class PhormColumn<T> {
  /// The name of the column as it exists in the database.
  final String name;

  /// The name of the table this column belongs to.
  final String? tableName;

  /// Creates a typed column reference named [name].
  const PhormColumn(this.name, {this.tableName});

  @override
  String toString() => tableName != null ? '$tableName.$name' : name;
}

/// Extensions for [PhormColumn] to enable fluent query building.
extension PhormColumnExtension<T> on PhormColumn<T> {
  /// Creates an equality condition: `column = value`
  PhormCondition eq(T value) => PhormCondition(this, '=', value);

  /// Creates an inequality condition: `column != value`
  PhormCondition ne(T value) => PhormCondition(this, '!=', value);

  /// Creates a greater-than condition: `column > value`
  PhormCondition gt(T value) => PhormCondition(this, '>', value);

  /// Creates a greater-than-or-equal condition: `column >= value`
  PhormCondition gte(T value) => PhormCondition(this, '>=', value);

  /// Creates a less-than condition: `column < value`
  PhormCondition lt(T value) => PhormCondition(this, '<', value);

  /// Creates a less-than-or-equal condition: `column <= value`
  PhormCondition lte(T value) => PhormCondition(this, '<=', value);

  /// Creates a LIKE condition: `column LIKE pattern`
  PhormCondition like(String pattern) => PhormCondition(this, 'LIKE', pattern);

  /// Creates a NOT LIKE condition: `column NOT LIKE pattern`
  PhormCondition notLike(String pattern) =>
      PhormCondition(this, 'NOT LIKE', pattern);

  /// Creates a case-insensitive LIKE condition: `LOWER(column) LIKE LOWER(pattern)`
  PhormCondition ilike(String pattern) =>
      PhormCondition(this, 'ILIKE', pattern);

  /// Creates a case-insensitive NOT LIKE condition: `LOWER(column) NOT LIKE LOWER(pattern)`
  PhormCondition notIlike(String pattern) =>
      PhormCondition(this, 'NOT ILIKE', pattern);

  /// Creates a REGEXP condition: `column REGEXP pattern`
  PhormCondition regexp(String pattern) =>
      PhormCondition(this, 'REGEXP', pattern);

  /// Creates an IN condition: `column IN (value1, value2, ...)`
  PhormCondition inList(List<T> values) => PhormCondition(this, 'IN', values);

  /// Creates a NOT IN condition: `column NOT IN (value1, value2, ...)`
  PhormCondition notInList(List<T> values) =>
      PhormCondition(this, 'NOT IN', values);

  /// Creates a BETWEEN condition: `column BETWEEN from AND to`
  PhormCondition between(T from, T to) =>
      PhormCondition(this, 'BETWEEN', [from, to]);

  /// Creates a NOT BETWEEN condition: `column NOT BETWEEN from AND to`
  PhormCondition notBetween(T from, T to) =>
      PhormCondition(this, 'NOT BETWEEN', [from, to]);

  /// Creates a STARTS WITH condition (sugar for LIKE 'pattern%')
  PhormCondition startsWith(String pattern) =>
      PhormCondition(this, 'STARTS WITH', pattern);

  /// Creates an ENDS WITH condition (sugar for LIKE '%pattern')
  PhormCondition endsWith(String pattern) =>
      PhormCondition(this, 'ENDS WITH', pattern);

  /// Creates an IS NULL condition.
  PhormCondition isNull() => PhormCondition(this, 'IS NULL', null);

  /// Creates an IS NOT NULL condition.
  PhormCondition isNotNull() => PhormCondition(this, 'IS NOT NULL', null);

  /// Creates a TRUE condition: `column = 1`
  PhormCondition isTrue() => PhormCondition(this, 'TRUE', null);

  /// Creates a FALSE condition: `column = 0`
  PhormCondition isFalse() => PhormCondition(this, 'FALSE', null);

  // =======================================================
  // STRING FUNCTIONS
  // =======================================================

  /// Creates a condition on the length of a column: `LENGTH(column) = ?`
  PhormCondition lengthEq(int length) =>
      PhormCondition(this, 'LENGTH =', length);

  /// Creates a condition on the length of a column: `LENGTH(column) != ?`
  PhormCondition lengthNe(int length) =>
      PhormCondition(this, 'LENGTH !=', length);

  /// Creates a condition on the length of a column: `LENGTH(column) > ?`
  PhormCondition lengthGt(int length) =>
      PhormCondition(this, 'LENGTH >', length);

  /// Creates a condition on the length of a column: `LENGTH(column) >= ?`
  PhormCondition lengthGte(int length) =>
      PhormCondition(this, 'LENGTH >=', length);

  /// Creates a condition on the length of a column: `LENGTH(column) < ?`
  PhormCondition lengthLt(int length) =>
      PhormCondition(this, 'LENGTH <', length);

  /// Creates a condition on the length of a column: `LENGTH(column) <= ?`
  PhormCondition lengthLte(int length) =>
      PhormCondition(this, 'LENGTH <=', length);

  /// Creates a SUBSTR equality: `SUBSTR(column, start, len) = ?`
  PhormCondition substrEq(int start, int len, String value) =>
      PhormCondition(this, 'SUBSTR =', [start, len, value]);

  /// Creates a SUBSTR LIKE condition: `SUBSTR(column, start, len) LIKE ?`
  PhormCondition substrLike(int start, int len, String pattern) =>
      PhormCondition(this, 'SUBSTR LIKE', [start, len, pattern]);

  /// Creates a case-insensitive SUBSTR LIKE: `LOWER(SUBSTR(column, start, len)) LIKE LOWER(?)`
  PhormCondition substrIlike(int start, int len, String pattern) =>
      PhormCondition(this, 'SUBSTR ILIKE', [start, len, pattern]);

  // =======================================================
  // DATE/TIME FUNCTIONS
  // =======================================================

  /// Creates a date-only equality: `DATE(column) = ?`
  PhormCondition dateOnlyEq(DateTime date) =>
      PhormCondition(this, 'DATE =', date);

  /// Creates a date-only greater-than: `DATE(column) > ?`
  PhormCondition dateOnlyGt(DateTime date) =>
      PhormCondition(this, 'DATE >', date);

  /// Creates a date-only less-than: `DATE(column) < ?`
  PhormCondition dateOnlyLt(DateTime date) =>
      PhormCondition(this, 'DATE <', date);

  /// Creates a date-only between range: `DATE(column) BETWEEN ? AND ?`
  PhormCondition dateOnlyBetween(DateTime from, DateTime to) =>
      PhormCondition(this, 'DATE BETWEEN', [from, to]);

  /// Creates a time-only equality: `TIME(column) = ?`
  PhormCondition timeOnlyEq(DateTime time) =>
      PhormCondition(this, 'TIME =', time);
}

/// Represents a single SQL condition built from a column and an operator.
class PhormCondition {
  /// The column the condition applies to.
  final PhormColumn<dynamic> column;

  /// The SQL comparison operator.
  final String operator;

  /// The bound value compared against.
  final dynamic value;

  /// Creates a `column operator value` condition.
  PhormCondition(this.column, this.operator, this.value);
}
