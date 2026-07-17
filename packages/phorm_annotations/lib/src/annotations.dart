import '../phorm_annotations.dart';

/// Strategy for naming database columns.
enum ColumnNamingStrategy {
  /// Use snake_case (e.g., `firstName` -> `first_name`).
  snakeCase,

  /// Use camelCase (e.g., `firstName` -> `firstName`).
  camelCase,

  /// Use PascalCase (e.g., `firstName` -> `FirstName`).
  pascalCase,
}

/// Target SQL dialect for schema (DDL) generation.
///
/// Tells the generator which database flavour to emit DDL for
/// (types, auto-increment, timestamp handling, etc.).
enum SqlDialectKind {
  /// SQLite. The default dialect.
  sqlite,

  /// PostgreSQL.
  postgres,

  /// MySQL / MariaDB.
  mysql,
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

  /// Concrete SQL type class definition (e.g. VARCHAR(256), DECIMAL(10, 2)).
  final SqlType? type;

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

  /// Creates a column annotation with the shared column options.
  const ColumnBase({
    this.sqlType,
    this.type,
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
  /// Creates a `@Column` annotation.
  const Column({
    super.sqlType,
    super.type,
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

  /// Creates an `@ID` primary-key annotation.
  const ID({
    super.sqlType,
    super.type,
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

  /// Whether to generate the PhormClassNameToJson method.
  final bool useToJson;

  /// Whether to generate the PhormClassNameFromJson method.
  final bool useFromJson;

  /// Whether to generate the copyWith method.
  final bool useCopyWith;

  /// Whether to automatically manage createdAt and updatedAt timestamps.
  final bool timestamps;

  /// Whether to generate the validate() method based on column CHECK constraints.
  final bool useValidator;

  /// Whether to generate the toString method helper.
  final bool useToString;

  /// Whether to generate the pluralized static service class
  /// (e.g. `Users`) that exposes the full CRUD/query API
  /// (`insert`, `readAll`, `where`, `watchAll`, column constants, …).
  ///
  /// Set to `false` to keep only the lightweight artefacts (schema, table,
  /// `fromJson`/`toJson`, `copyWith`) and skip the large generated service.
  /// Defaults to `true`.
  final bool generateFullService;

  /// Target SQL dialect the generator emits DDL for.
  ///
  /// Defaults to [SqlDialectKind.sqlite].
  final SqlDialectKind dialect;

  /// Whether to automatically create indexes on foreign key columns of
  /// `BelongsTo`/`Join` relationships (and on auto-generated pivot tables).
  ///
  /// Foreign key indexes make relationship loading scale linearly instead of
  /// quadratically: without one, fetching a parent with its children scans
  /// the child table once **per parent row**. Defaults to `true`.
  final bool indexForeignKeys;

  /// Creates a `@Schema` table annotation.
  const Schema({
    this.tableName,
    this.indexes = const [],
    this.paranoid = false,
    this.columnNaming = ColumnNamingStrategy.snakeCase,
    this.dialect = SqlDialectKind.sqlite,
    this.relationships = const [],
    this.useToJson = true,
    this.useFromJson = true,
    this.useCopyWith = true,
    this.useToString = true,
    this.timestamps = true,
    this.useValidator = true,
    this.generateFullService = true,
    this.indexForeignKeys = true,
  });
}

/// Base class for relationship annotations between two models.
abstract class Relationship {
  /// The target model for the relationship.
  /// Can be a [String] (table name) or a [Type] (Model class).
  final dynamic model;

  /// The foreign-key column of the relationship.
  final String foreignKey;

  /// The local key column this relationship joins on.
  final String localKey;

  /// Action applied when the referenced record is deleted.
  final String? onDelete;

  /// Action applied when the referenced record is updated.
  final String? onUpdate;

  /// Creates a relationship with the given model and key columns.
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
  /// Creates a one-to-many relationship.
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

/// A one-to-one relationship where the related table holds the foreign key.
class HasOne extends Relationship {
  /// Creates a one-to-one relationship.
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

/// The inverse side of a relationship: this table holds the foreign key.
class BelongsTo extends Relationship {
  /// Creates the inverse (owning-side) relationship.
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

/// Alias of [BelongsTo] kept for query-join readability.
class Join extends BelongsTo {
  /// Creates a join (inverse) relationship.
  const Join({
    required super.model,
    required super.foreignKey,
    super.localKey = 'id',
    super.onDelete,
    super.onUpdate,
  });
}

/// A many-to-many relationship resolved through a pivot table.
class ManyToMany extends Relationship {
  /// The name of the pivot (join) table.
  final String pivotTable;

  /// The column in the pivot table that points to the related model.
  final String relatedKey;

  /// The column in the related model that is referenced by [relatedKey].
  final String relatedLocalKey;

  /// Whether the code generator should emit a `CREATE TABLE IF NOT EXISTS`
  /// statement for the [pivotTable] automatically.
  ///
  /// When `true`, the generated schema includes a minimal pivot table with the
  /// [foreignKey] and [relatedKey] columns and a composite primary key over
  /// both. When `false` (the default) the pivot table must be created manually
  /// (e.g. via a migration), preserving backwards-compatible behaviour.
  final bool createPivot;

  /// Whether the auto-generated pivot table (see [createPivot]) should also
  /// include `FOREIGN KEY (...) REFERENCES ... ON DELETE CASCADE` constraints
  /// for both pivot columns.
  ///
  /// Only takes effect together with `createPivot: true`. When enabled, the
  /// [foreignKey] column references the owning model's [localKey] and the
  /// [relatedKey] column references the related model's [relatedLocalKey], both
  /// with `ON DELETE CASCADE` so pivot rows are cleaned up automatically.
  ///
  /// Note: SQLite cannot add foreign keys to an existing table, so enabling
  /// this on a pivot that was already created without constraints requires a
  /// manual table-recreation migration.
  final bool pivotForeignKeys;

  /// Creates a many-to-many relationship via a pivot table.
  const ManyToMany({
    required super.model,
    required this.pivotTable,
    required super.foreignKey,
    required this.relatedKey,
    super.localKey = 'id',
    this.relatedLocalKey = 'id',
    this.createPivot = false,
    this.pivotForeignKeys = false,
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

  /// Creates an index over [columns]; set [unique] for a unique index.
  const Index({required this.columns, this.unique = false});
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
  static Includable table(
    String name, {
    Attributes? attributes,
    List<Includable>? include,
  }) => _TableIncludable(name, attributes: attributes, include: include);

  /// Includes a relationship by its model class type.
  ///
  /// Provides compile-time safety and refactoring support.
  static Includable model<T>({
    Attributes? attributes,
    List<Includable>? include,
  }) => _ModelIncludable<T>(attributes: attributes, include: include);
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
      'Table for model type $T not found in registered tables.',
    );
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
/// 2. Generate type-safe [PhormColumn] extension methods for calling this function.
class SqlFunc {
  /// The SQLite-native name of the custom SQL function.
  /// If null, the generator defaults to the UPPERCASE version of the Dart function name.
  final String? name;

  /// Creates a `@SqlFunc` annotation, optionally overriding the SQL [name].
  const SqlFunc({this.name});
}
