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
  /// Explicit name of the column in the database.
  ///
  /// If provided, overrides the [ColumnNamingStrategy] set on the [Schema].
  final String? columnName;

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
    this.columnName,
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
    super.columnName,
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
    super.columnName,
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
  final List<Relationship> relationships;

  /// Whether to generate the SQFlowClassNameToJson method.
  final bool useToJson;

  /// Whether to generate the SQFlowClassNameFromJson method.
  final bool useFromJson;

  const Schema({
    this.tableName,
    this.indexes = const [],
    this.paranoid = false,
    this.columnNaming = ColumnNamingStrategy.snakeCase,
    this.relationships = const [],
    this.useToJson = true,
    this.useFromJson = true,
  });
}

abstract class Relationship {
  /// The target model for the relationship.
  /// Can be a [String] (table name) or a [Type] (Model class).
  final dynamic model;
  final String foreignKey;
  final String localKey;

  const Relationship({
    required this.model,
    required this.foreignKey,
    this.localKey = 'id',
  });

  /// True if the relationship returns a collection of models.
  bool get isCollection;
}

/// Relationship definitions
class HasMany extends Relationship {
  const HasMany({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
  });

  @override
  bool get isCollection => true;
}

class HasOne extends Relationship {
  const HasOne({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
  });

  @override
  bool get isCollection => false;
}

class BelongsTo extends Relationship {
  const BelongsTo({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
  });

  @override
  bool get isCollection => false;
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

/// Base interface for specifying relationships to include in a query.
///
/// Use [Includable.table] to include by table name (String)
/// or [Includable.model] to include by model type (Type).
abstract interface class Includable {
  /// Resolves the table name for the relationship.
  ///
  /// Takes a list of available tables to perform type-to-name lookup.
  String getTableName(List<dynamic> availableTables);

  /// Includes a relationship by its explicit table name.
  static Includable table(String name) => _TableIncludable(name);

  /// Includes a relationship by its model class type.
  ///
  /// Provides compile-time safety and refactoring support.
  static Includable model<T>() => _ModelIncludable<T>();
}

class _TableIncludable implements Includable {
  final String name;
  _TableIncludable(this.name);

  @override
  String getTableName(List<dynamic> _) => name;
}

class _ModelIncludable<T> implements Includable {
  @override
  String getTableName(List<dynamic> availableTables) {
    for (final table in availableTables) {
      // Use dynamic access because we don't want to depend on Table class here
      // to avoid circular dependencies in platform interface if any.
      // But in practice, we know it's a list of Table objects.
      if (table.type == T) return table.name as String;
    }
    throw ArgumentError('Table for model type $T not found in registered tables.');
  }
}
