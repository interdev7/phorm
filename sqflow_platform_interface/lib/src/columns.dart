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
  SqflowCondition equals(T value) => SqflowCondition(this, '=', value);

  /// Creates an inequality condition: `column != value`
  SqflowCondition notEquals(T value) => SqflowCondition(this, '!=', value);

  /// Creates a greater-than condition: `column > value`
  SqflowCondition greaterThan(T value) => SqflowCondition(this, '>', value);

  /// Creates a greater-than-or-equal condition: `column >= value`
  SqflowCondition greaterThanOrEqual(T value) =>
      SqflowCondition(this, '>=', value);

  /// Creates a less-than condition: `column < value`
  SqflowCondition lessThan(T value) => SqflowCondition(this, '<', value);

  /// Creates a less-than-or-equal condition: `column <= value`
  SqflowCondition lessThanOrEqual(T value) =>
      SqflowCondition(this, '<=', value);

  /// Creates a LIKE condition: `column LIKE pattern`
  SqflowCondition like(String pattern) => SqflowCondition(this, 'LIKE', pattern);

  /// Creates an IN condition: `column IN (value1, value2, ...)`
  SqflowCondition inList(List<T> values) => SqflowCondition(this, 'IN', values);

  /// Creates an IS NULL condition.
  SqflowCondition isNull() => SqflowCondition(this, 'IS NULL', null);

  /// Creates an IS NOT NULL condition.
  SqflowCondition isNotNull() => SqflowCondition(this, 'IS NOT NULL', null);
}

/// Represents a single SQL condition built from a column and an operator.
class SqflowCondition {
  final SqflowColumn<dynamic> column;
  final String operator;
  final dynamic value;

  SqflowCondition(this.column, this.operator, this.value);
}

/// A representation of a table definition with typed columns.
abstract class TableType {
  /// The name of the table.
  String get tableName;
}
