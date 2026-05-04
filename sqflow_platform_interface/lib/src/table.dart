import '../src/models.dart';
import '../src/table_migration.dart';
import '../src/migration_builder.dart';
import '../src/annotations.dart';

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
  });

  /// Helper to detect if a schema string contains soft-delete capability.
  static bool detectSoftDelete(String schema) {
    final normalized = schema.toLowerCase();
    return normalized.contains('deleted_at') &&
        normalized.contains('create table');
  }
}
