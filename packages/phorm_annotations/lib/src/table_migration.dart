import 'executor.dart';
import 'models.dart';
import 'table.dart';

// =======================================================
// TABLE MIGRATION
// =======================================================
///
/// Represents a single migration operation for a table.
///
/// **Properties:**
/// - `table`: The table this migration applies to
/// - `targetVersion`: Database version when this migration should be applied
/// - `description`: Human-readable description for logging
/// - `migrate`: Async function that performs the migration
/// - `priority`: Execution order within the same version (lower = earlier)
class TableMigration<T extends Model> {
  /// The table this migration applies to.
  final Table<T> table;

  /// Schema version this migration upgrades to.
  final int targetVersion;

  /// Human-readable description shown in logs.
  final String description;

  /// Async function that performs the migration.
  final Future<void> Function(PhormDatabaseExecutor db, Table<Model> table)
  migrate;

  /// Execution order within the same version (lower runs earlier).
  final int priority;

  /// Creates a migration definition.
  TableMigration({
    required this.table,
    required this.targetVersion,
    required this.description,
    required this.migrate,
    this.priority = 0,
  });
}
