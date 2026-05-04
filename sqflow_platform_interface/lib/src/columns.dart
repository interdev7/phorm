/// A typed representation of a database column.
/// Used for building type-safe queries.
class SqflowColumn<T> {
  /// The name of the column as it exists in the database.
  final String name;

  const SqflowColumn(this.name);

  @override
  String toString() => name;
}

/// A representation of a table definition with typed columns.
abstract class TableType {
  /// The name of the table.
  String get tableName;
}
