import 'dart:convert';

import 'annotations.dart';
import 'migration_builder.dart';
import 'models.dart';
import 'table_migration.dart';

/// Positional row factory: given the result set's `column name → index` map
/// (resolved **once** per query), returns a per-row function that builds the
/// model by reading values directly from the positional [List] — no per-row
/// map construction or string-keyed lookups.
///
/// Produced by `phorm_generator`; hand-written [Table]s may provide one for
/// maximum read throughput, or leave it `null` to use [Table.fromJson].
typedef PhormRowBinder<T> =
    T Function(List<Object?> row) Function(Map<String, int> columnIndex);

/// Decodes a raw column value that may carry serialized JSON (nested object
/// columns, aggregated relationship columns): JSON-looking strings are parsed,
/// everything else is returned as-is. Mirrors the map-based read path.
Object? phormDecodeJson(Object? value) {
  if (value is String &&
      value.isNotEmpty &&
      (value.codeUnitAt(0) == 0x5b || value.codeUnitAt(0) == 0x7b)) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }
  return value;
}

/// Represents a fully generated table schema.
///
/// This class binds together:
/// - the SQL schema definition
/// - the table name
/// - a row-to-entity mapping function
/// - table-level behavioral options
///
/// It is typically produced by code generation and
/// used internally by the runtime layer.
class Table<T extends Model> {
  /// SQL definition used to create the table.
  ///
  /// Usually contains a CREATE TABLE statement
  /// and optional index definitions.
  final String schema;

  /// Name of the database table.
  final String name;

  /// Primary key column name (default is 'id').
  final String primaryKey;

  /// List of migrations for this table
  final List<TableMigration<T>> migrations;

  /// Factory function that converts a database row
  /// into a strongly-typed entity instance.
  ///
  /// The input map represents a single row,
  /// where keys are column names.
  final T Function(Map<String, dynamic>) fromJson;

  /// Enables soft deletion behavior for the table.
  ///
  /// When enabled, records are marked as deleted
  /// instead of being physically removed.
  final bool paranoid;

  /// Relationships
  final List<Relationship> relationships;

  /// Associated model type
  final Type type;

  /// List of column names in the table.
  final List<String> columns;

  /// Creates a migration builder for this table
  ///
  /// **Example:**
  /// ```dart
  /// final migrations = table.migrate()
  ///   .addColumn(name: 'age', type: 'INTEGER', version: 2)
  ///   .createIndex(name: 'idx_email', columns: ['email'], version: 3)
  ///   .build();
  /// ```
  MigrationBuilder<T> migrate() => MigrationBuilder<T>(this);

  /// Enables automatic timestamps (created_at, updated_at).
  final bool timestamps;

  /// Whether the primary key column is AUTOINCREMENT.
  /// If not provided explicitly, auto-detected from the schema SQL.
  final bool autoIncrement;

  /// Optional positional row factory used by the columnar read fast path.
  ///
  /// When set, model reads without `include` skip per-row map construction
  /// entirely: column indices are resolved once per result set and values
  /// are read positionally. Falls back to [fromJson] when `null`.
  final PhormRowBinder<T>? rowBinder;

  /// Creates a table configuration.
  Table({
    required this.schema,
    required this.name,
    required this.fromJson,
    required this.type,
    this.primaryKey = 'id',
    this.migrations = const [],
    this.paranoid = false,
    this.timestamps = true,
    this.relationships = const [],
    this.columns = const [],
    this.rowBinder,
    bool? autoIncrement,
  }) : autoIncrement = autoIncrement ?? detectAutoIncrement(schema);

  /// Helper to detect if a schema string contains soft-delete capability.
  static bool detectSoftDelete(String schema) {
    final normalized = schema.toLowerCase();
    return normalized.contains('deleted_at') &&
        normalized.contains('create table');
  }

  /// Helper to detect if the primary key uses AUTOINCREMENT.
  static bool detectAutoIncrement(String schema) {
    return schema.toUpperCase().contains('AUTOINCREMENT');
  }
}
