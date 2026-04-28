import 'data_type.dart';

/// Strategy for naming database columns.
enum ColumnNamingStrategy {
  /// Use snake_case (e.g., `firstName` -> `first_name`).
  snakeCase,

  /// Use camelCase (e.g., `firstName` -> `firstName`).
  camelCase,

  /// Use PascalCase (e.g., `firstName` -> `FirstName`).
  pascalCase,
}

/// Base class for all column definitions.
///
/// Contains properties common to any table column,
/// such as type, nullability, uniqueness, defaults,
/// and value constraints.
abstract class ColumnBase {
  /// Database data type of the column.
  final DataType type;

  /// Whether the column enforces uniqueness.
  ///
  /// Adds a UNIQUE constraint.
  final bool unique;

  /// Default value used when no value is provided.
  final dynamic defaultValue;

  /// Optional value constraint.
  ///
  /// Can be used to restrict allowed values.
  final CHECK? check;

  const ColumnBase({
    required this.type,
    this.unique = false,
    this.defaultValue,
    this.check,
  });
}

/// Standard column definition.
///
/// Used for most non-key fields.
class Column extends ColumnBase {
  const Column({
    required super.type,
    super.unique,
    super.defaultValue,
    super.check,
  });
}

/// Primary key column.
///
/// Intended for identifier fields.
class ID extends ColumnBase {
  /// Whether the value is generated automatically.
  ///
  /// For example, auto-incrementing integers.
  final bool autoIncrement;

  const ID({
    required super.type,
    this.autoIncrement = false,
    super.unique = true,
  });
}

/// Table-level schema configuration.
class Schema {
  /// Optional explicit table name.
  ///
  /// If not provided, a default naming strategy may be used.
  final String? tableName;

  /// List of indexes defined on the table.
  final List<Index> indexes;

  /// Enables soft deletion support.
  ///
  /// When enabled, records are marked as deleted
  /// instead of being physically removed.
  final bool paranoid;

  final ColumnNamingStrategy columnNaming;

  /// Relationships defined on the table.
  final List<HasMany> hasMany;
  final List<HasOne> hasOne;
  final List<BelongsTo> belongsTo;

  const Schema({
    this.tableName,
    this.indexes = const [],
    this.paranoid = false,
    this.columnNaming = ColumnNamingStrategy.snakeCase,
    this.hasMany = const [],
    this.hasOne = const [],
    this.belongsTo = const [],
  });
}

/// Relationship definitions
class HasMany {
  final String model;
  final String foreignKey;
  final String localKey;
  const HasMany({
    required this.model,
    required this.foreignKey,
    this.localKey = 'id',
  });
}

class HasOne {
  final String model;
  final String foreignKey;
  final String localKey;
  const HasOne({
    required this.model,
    required this.foreignKey,
    this.localKey = 'id',
  });
}

class BelongsTo {
  final String model;
  final String foreignKey;
  final String localKey;
  const BelongsTo({
    required this.model,
    required this.foreignKey,
    this.localKey = 'id',
  });
}

class Join extends BelongsTo {
  const Join({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
  });
}

/// Database index definition.
class Index {
  /// Columns included in the index.
  final List<String> columns;

  /// Whether the index enforces uniqueness.
  final bool unique;

  const Index({
    required this.columns,
    this.unique = false,
  });
}

/// Value constraint definition.
///
/// Restricts column values to a predefined set.
class CHECK {
  /// Allowed values for the column.
  final dynamic checker;

  /// Custom constraint expression.
  final String? constraint;

  const CHECK(this.checker, {this.constraint});
}

/// Foreign key column.
///
/// Represents a reference to another table.
class ForeignKey extends ColumnBase {
  /// Referenced table name.
  final String referencesTable;

  /// Referenced column name.
  final String referencesColumn;

  /// Action applied when the referenced record is deleted.
  final String? onDelete;

  /// Action applied when the referenced record is updated.
  final String? onUpdate;

  const ForeignKey({
    required super.type,
    required this.referencesTable,
    required this.referencesColumn,
    this.onDelete,
    this.onUpdate,
  });
}
