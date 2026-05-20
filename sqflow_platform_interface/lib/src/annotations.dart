import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

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
  ///
  /// By default, the generator infers this from the Dart field type.
  /// If you want to explicitly override the SQLite type (e.g. 'VARCHAR(255)', 'JSON'), set this field.
  final String? sqlType;

  /// Whether the column enforces uniqueness.
  ///
  /// Adds a UNIQUE constraint.
  final bool unique;

  /// Default value used when no value is provided.
  final dynamic defaultValue;

  /// Optional value constraint.
  ///
  /// Can be used to restrict allowed values.
  final List<IValidator>? validators;

  /// Optional value converter for mapping between Dart and SQL types.
  final ValueConverter<dynamic, dynamic>? converter;

  /// Optional collation sequence.
  ///
  /// Use [Collate.noCase], [Collate.binary], or [Collate.rtrim].
  final String? collate;

  const ColumnBase({
    this.sqlType,
    this.columnName,
    this.unique = false,
    this.defaultValue,
    this.validators,
    this.converter,
    this.collate,
  });
}

/// Standard column definition.
///
/// Used for most non-key fields.
class Column extends ColumnBase {
  const Column({
    super.sqlType,
    super.columnName,
    super.unique = false,
    super.defaultValue,
    super.validators,
    super.converter,
    super.collate,
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
    super.sqlType,
    super.columnName,
    this.autoIncrement = false,
    super.unique = true,
    super.collate,
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

  /// The strategy used for naming columns.
  ///
  /// Defaults to [ColumnNamingStrategy.snakeCase].
  final ColumnNamingStrategy columnNaming;

  /// Relationships defined on the table.
  final List<Relationship> relationships;

  /// Whether to generate the SQFlowClassNameToJson method.
  final bool useToJson;

  /// Whether to generate the SQFlowClassNameFromJson method.
  final bool useFromJson;

  /// Whether to generate the copyWith method.
  final bool useCopyWith;

  /// Whether to automatically manage createdAt and updatedAt timestamps.
  final bool timestamps;

  /// Whether to generate the validate() method based on column CHECK constraints.
  final bool useValidator;

  /// Whether to generate the toString method helper.
  final bool useToString;

  const Schema({
    this.tableName,
    this.indexes = const [],
    this.paranoid = false,
    this.columnNaming = ColumnNamingStrategy.snakeCase,
    this.relationships = const [],
    this.useToJson = true,
    this.useFromJson = true,
    this.useCopyWith = true,
    this.useToString = true,
    this.timestamps = true,
    this.useValidator = true,
  });
}

abstract class Relationship {
  /// The target model for the relationship.
  /// Can be a [String] (table name) or a [Type] (Model class).
  final dynamic model;
  final String foreignKey;
  final String localKey;

  /// Action applied when the referenced record is deleted.
  final String? onDelete;

  /// Action applied when the referenced record is updated.
  final String? onUpdate;

  const Relationship({
    required this.model,
    required this.foreignKey,
    this.localKey = 'id',
    this.onDelete,
    this.onUpdate,
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
    super.onDelete,
    super.onUpdate,
  });

  @override
  bool get isCollection => true;
}

class HasOne extends Relationship {
  const HasOne({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
    super.onDelete,
    super.onUpdate,
  });

  @override
  bool get isCollection => false;
}

class BelongsTo extends Relationship {
  const BelongsTo({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
    super.onDelete,
    super.onUpdate,
  });

  @override
  bool get isCollection => false;
}

class Join extends BelongsTo {
  const Join({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
    super.onDelete,
    super.onUpdate,
  });
}

class ManyToMany extends Relationship {
  /// The name of the pivot (join) table.
  final String pivotTable;

  /// The column in the pivot table that points to the related model.
  final String relatedKey;

  /// The column in the related model that is referenced by [relatedKey].
  final String relatedLocalKey;

  const ManyToMany({
    required super.model,
    required this.pivotTable,
    required super.foreignKey,
    required this.relatedKey,
    super.localKey = 'id',
    this.relatedLocalKey = 'id',
    super.onDelete,
    super.onUpdate,
  });

  @override
  bool get isCollection => true;
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

/// Base interface for specifying relationships to include in a query.
///
/// Use [Includable.table] to include by table name (String)
/// or [Includable.model] to include by model type (Type).
abstract interface class Includable {
  /// Resolves the table name for the relationship.
  ///
  /// Takes a list of available tables to perform type-to-name lookup.
  String getTableName(List<Table> availableTables);

  /// Optional attribute filter for the included model.
  Attributes? get attributes;

  /// Optional nested includes for deep loading.
  List<Includable>? get include;

  /// Includes a relationship by its explicit table name.
  static Includable table(String name,
          {Attributes? attributes, List<Includable>? include}) =>
      _TableIncludable(name, attributes: attributes, include: include);

  /// Includes a relationship by its model class type.
  ///
  /// Provides compile-time safety and refactoring support.
  static Includable model<T>(
          {Attributes? attributes, List<Includable>? include}) =>
      _ModelIncludable<T>(attributes: attributes, include: include);
}

class _TableIncludable implements Includable {
  final String name;
  @override
  final Attributes? attributes;
  @override
  final List<Includable>? include;

  _TableIncludable(this.name, {this.attributes, this.include});

  @override
  String getTableName(List<dynamic> _) => name;
}

class _ModelIncludable<T> implements Includable {
  @override
  final Attributes? attributes;
  @override
  final List<Includable>? include;

  _ModelIncludable({this.attributes, this.include});

  @override
  String getTableName(List<Table> availableTables) {
    for (final table in availableTables) {
      // Use dynamic access because we don't want to depend on Table class here
      // to avoid circular dependencies in platform interface if any.
      // But in practice, we know it's a list of Table objects.
      if (table.type == T) return table.name;
    }
    throw ArgumentError(
        'Table for model type $T not found in registered tables.');
  }
}

/// Interface for attribute filtering in queries (columns selection).
abstract interface class Attributes {
  /// Includes only the specified columns.
  static Attributes include(List<String> columns) =>
      _IncludeAttributes(columns);

  /// Excludes the specified columns.
  static Attributes exclude(List<String> columns) =>
      _ExcludeAttributes(columns);

  /// Applies the filter to the given list of columns.
  List<String> apply(List<String> allColumns);
}

class _IncludeAttributes implements Attributes {
  final List<String> columns;
  _IncludeAttributes(this.columns);

  @override
  List<String> apply(List<String> allColumns) => columns;
}

class _ExcludeAttributes implements Attributes {
  final List<String> columns;
  _ExcludeAttributes(this.columns);

  @override
  List<String> apply(List<String> allColumns) {
    return allColumns.where((c) => !columns.contains(c)).toList();
  }
}

/// Annotation to mark a custom Dart function as a SQLite custom function.
///
/// The generator will scan all functions marked with `@SqlFunc` and:
/// 1. Create a list of custom SQL function registrations in `custom_functions.g.dart`.
/// 2. Generate type-safe [SqflowColumn] extension methods for calling this function.
class SqlFunc {
  /// The SQLite-native name of the custom SQL function.
  /// If null, the generator defaults to the UPPERCASE version of the Dart function name.
  final String? name;

  const SqlFunc({this.name});
}
