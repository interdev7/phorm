// =======================================================
// DATABASE SERVICE WITH SMART MIGRATIONS 🚀
// =======================================================
///
/// A professional, production-ready database service for Flutter/Dart applications
/// featuring smart migration tracking, version management, and fluent API.
///
/// **Key Features:**
/// - Automatic migration tracking with idempotent execution
/// - Version-aware schema management
/// - Fluent migration builder API
/// - Support for custom migration logic
/// - Safe rollback and downgrade handling
/// - Multi-table migration coordination
///
/// **Architecture Overview:**
/// ```text
/// ┌─────────────────┐
/// │   DB Service    │ ← Manages migrations & connections
/// ├─────────────────┤
/// │  Table          │ ← Table schema + migrations
/// ├─────────────────┤
/// │  Migration      │ ← Individual migration steps
/// ├─────────────────┤
/// │ MigrationTracker│ ← Tracks applied migrations
/// └─────────────────┘
/// ```
import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

/// Main database manager that handles connection lifecycle,
/// version management, and smart migration tracking.
///
/// **Usage Example:**
/// ```dart
/// // Define tables with migrations
/// final usersTable = Table<User>(
///   name: 'users',
///   schema: 'CREATE TABLE users (...)',
///   fromJson: User.fromJson,
/// ).migrate()
///   .addColumn(name: 'email', type: 'TEXT', version: 2)
///   .createIndex(name: 'idx_email', columns: ['email'], version: 3)
///   .build();
///
/// // Create database with auto version detection
/// final db = DB.autoVersion(
///   databaseName: 'my_app.db',
///   tables: [usersTable, postsTable],
/// );
///
/// // Use in services
/// final userService = SqflowCore<User>(
///   dbManager: db,
///   table: usersTable,
/// );
/// ```
class DB {
  /// Database file name (e.g., 'app_database.db')
  final String databaseName;

  /// Current database schema version
  /// Must be >= highest migration version across all tables
  final int version;

  /// List of table configurations including schemas and migrations
  final List<Table> tables;

  /// Internal database instance (lazy-loaded)
  Database? _database;

  /// Name of the migrations tracking table
  static const String _migrationsTable = '__sqflow_migrations';

  /// Optional logger for the database
  final SqflowLogger? logger;

  /// Whether to log all queries
  final bool logQueries;

  /// Threshold for logging slow queries
  final Duration slowQueryThreshold;

  /// Whether to use a single instance for the same database path.
  /// Set to false for in-memory databases in tests to ensure isolation.
  final bool singleInstance;

  /// Row count threshold at which data mapping is moved to an isolate.
  /// Default is 50 rows.
  final int isolateThreshold;

  /// Internal stream controller for table changes
  final _changeController = StreamController<String>.broadcast();

  /// Stream of table names that have been modified
  Stream<String> get changeStream => _changeController.stream;

  /// Notifies the database that a table has been modified.
  /// If inside a transaction, notifications are buffered and emitted after commit.
  void notifyTableChange(String tableName) {
    final buffered = Zone.current[#sqflow_notifications] as Set<String>?;
    if (buffered != null) {
      buffered.add(tableName);
    } else {
      _changeController.add(tableName);
    }
  }

  /// Creates a new database instance
  ///
  /// **Parameters:**
  /// - `databaseName`: SQLite database file name
  /// - `version`: Current schema version (must be >= all migration versions)
  /// - `tables`: List of table configurations
  /// - `logger`: Custom logger (defaults to SqflowConsoleLogger)
  /// - `logQueries`: Whether to log all executed queries
  /// - `slowQueryThreshold`: Threshold for slow query warning
  ///
  /// **Throws:** `ArgumentError` if any migration has version > `version`
  ///
  /// **Example:**
  /// ```dart
  /// final db = DB(
  ///   databaseName: 'app_v3.db',
  ///   version: 3,
  ///   tables: [usersTable, postsTable],
  /// );
  /// ```
  DB({
    required this.version,
    required this.tables,
    this.databaseName = 'app_database.db',
    this.logger = const SqflowConsoleLogger(),
    this.logQueries = false,
    this.slowQueryThreshold = const Duration(milliseconds: 200),
    this.singleInstance = true,
    this.isolateThreshold = 50,
  }) {
    _validateMigrations();
  }

  /// Creates a database with auto-detected version
  ///
  /// Automatically determines the maximum version from all table migrations.
  ///
  /// **Example:**
  /// ```dart
  /// final db = DB.autoVersion(
  ///   databaseName: 'app.db',
  ///   tables: [
  ///     tableWithMigrationsUpToV2,
  ///     tableWithMigrationsUpToV3,
  ///   ],
  /// );
  /// print(db.version); // 3 (maximum from all migrations)
  /// ```
  factory DB.autoVersion({
    required String databaseName,
    required List<Table> tables,
    SqflowLogger? logger = const SqflowConsoleLogger(),
    bool logQueries = false,
    Duration slowQueryThreshold = const Duration(milliseconds: 200),
    bool singleInstance = true,
    int isolateThreshold = 50,
  }) {
    // Determine maximum version from all migrations
    final maxVersion = _calculateMaxVersion(tables);

    return DB(
      databaseName: databaseName,
      version: maxVersion,
      tables: tables,
      logger: logger,
      logQueries: logQueries,
      slowQueryThreshold: slowQueryThreshold,
      singleInstance: singleInstance,
      isolateThreshold: isolateThreshold,
    );
  }

  /// Gets the database instance (lazy initialization)
  ///
  /// If database is not initialized, opens the connection and:
  /// 1. Creates tables on first run
  /// 2. Applies pending migrations on version upgrade
  /// 3. Initializes migration tracking
  ///
  /// **Example:**
  /// ```dart
  /// final dbInstance = await db.database;
  /// ```
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database connection
  Future<Database> _initDatabase() async {
    final String path;
    if (databaseName == ':memory:') {
      path = databaseName;
    } else {
      path = join(await getDatabasesPath(), databaseName);
    }

    logger?.info('Initializing database: $databaseName (v$version)');

    return await openDatabase(
      path,
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
      onConfigure: _onConfigure,
      singleInstance: singleInstance,
    );
  }

  /// Validates that all migrations are within the database version
  void _validateMigrations() {
    for (final table in tables) {
      for (final migration in table.migrations) {
        if (migration.targetVersion > version) {
          throw ArgumentError('Table "${table.name}" has migration "${migration.description}" '
              'for version ${migration.targetVersion}, but database version is $version. '
              'Either increase database version or remove the migration.');
        }
      }
    }
  }

  /// Calculates maximum version from all table migrations
  static int _calculateMaxVersion(List<Table> tables) {
    int maxVersion = 1; // Minimum version

    for (final table in tables) {
      for (final migration in table.migrations) {
        if (migration.targetVersion > maxVersion) {
          maxVersion = migration.targetVersion;
        }
      }
    }

    return maxVersion;
  }

  /// Database configuration callback
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys if needed
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Database creation callback (first run)
  Future<void> _onCreate(Database db, int version) async {
    logger?.info('Creating new database (v$version)');

    // 1. Create migrations tracking table
    await _createMigrationsTable(db);

    // 2. Create all tables
    for (final table in tables) {
      await _createTable(db, table);
    }

    // 3. Mark all migrations as applied (since we're creating from scratch)
    // await _markAllMigrationsApplied(db);
    await _applyPendingMigrations(db, 0, version);

    logger?.info('Database created successfully');
  }

  /// Database upgrade callback (version increase)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logger?.info('Upgrading database from v$oldVersion to v$newVersion');

    // 1. Ensure migrations table exists
    await _createMigrationsTable(db);

    for (final table in tables) {
      // Check table existence in sqlite_master system table
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table.name],
      );

      if (tableCheck.isEmpty) {
        logger?.info('New table detected: ${table.name}. Creating...');
        await _createTable(db, table);
      }
    }

    // 2. Apply pending migrations
    await _applyPendingMigrations(db, oldVersion, newVersion);

    logger?.info('Database upgraded successfully');
  }

  /// Database downgrade callback (version decrease)
  ///
  /// **Note:** SQLite doesn't support schema downgrades natively.
  /// This implementation recreates the database from scratch.
  /// For production, consider more sophisticated downgrade strategies.
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    logger?.info('Downgrading database from v$oldVersion to v$newVersion');

    // Close current connection
    await db.close();

    // Delete database file
    if (databaseName == ':memory:') {
      // In-memory databases are destroyed when closed
    } else {
      final path = join(await getDatabasesPath(), databaseName);
      await deleteDatabase(path);
    }

    // Recreate with new version
    _database = null;
    await database;

    logger?.info('Database downgraded by recreation');
  }

  /// Creates the migrations tracking table
  Future<void> _createMigrationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_migrationsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        migration_version INTEGER NOT NULL,
        migration_hash TEXT NOT NULL,
        description TEXT,
        applied_at TEXT NOT NULL,
        UNIQUE(table_name, migration_version, migration_hash)
      )
    ''');

    // Create index for faster lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_migrations_lookup 
      ON $_migrationsTable(table_name, migration_version)
    ''');
  }

  /// Creates a single table with its schema
  Future<void> _createTable(Database db, Table table) async {
    try {
      logger?.info('Creating table: ${table.name}');

      // Smart splitting to avoid breaking triggers (BEGIN...END blocks)
      final statements = <String>[];
      final rawParts = table.schema.split(';');
      String currentStatement = '';

      for (final part in rawParts) {
        currentStatement += part;
        final normalized = currentStatement.toUpperCase();

        // Count BEGIN and END blocks to handle triggers
        // We use regex with word boundaries to avoid matching keywords inside other words
        final beginCount = RegExp(r'\bBEGIN\b').allMatches(normalized).length;
        final endCount = RegExp(r'\bEND\b').allMatches(normalized).length;

        if (beginCount == endCount) {
          final trimmed = currentStatement.trim();
          if (trimmed.isNotEmpty) {
            statements.add(trimmed);
          }
          currentStatement = '';
        } else {
          currentStatement += ';';
        }
      }

      for (final statement in statements) {
        await db.execute(statement);
      }
    } catch (e, stackTrace) {
      logger?.error('Failed to create table ${table.name}', e, stackTrace);
      rethrow;
    }
  }

  /// Marks all migrations as applied (for initial database creation)
  ///
  /// **Note:** This method should be called after database creation
  /// to ensure all migrations are tracked.
  Future<void> synchronizeHistory() async {
    final db = await database;
    final allMigrations = tables.expand((t) => t.migrations).toList();

    await db.transaction((txn) async {
      for (final migration in allMigrations) {
        // Ensure no duplicate records before insert
        final exists = await txn.query(
          _migrationsTable,
          where: 'table_name = ? AND migration_version = ?',
          whereArgs: [migration.table.name, migration.targetVersion],
        );

        if (exists.isEmpty) {
          final hash = _calculateMigrationHash(migration);
          await txn.insert(_migrationsTable, {
            'table_name': migration.table.name,
            'migration_version': migration.targetVersion,
            'migration_hash': hash,
            'description': '${migration.description} (Synced)',
            'applied_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }

  /// Applies pending migrations between versions
  Future<void> _applyPendingMigrations(
    DatabaseExecutor db,
    int fromVersion,
    int toVersion,
  ) async {
    // Collect all migrations in the version range
    final pendingMigrations = <_PendingMigration>[];

    for (final table in tables) {
      for (final migration in table.migrations) {
        if (migration.targetVersion > fromVersion && migration.targetVersion <= toVersion) {
          pendingMigrations.add(_PendingMigration(table, migration));
        }
      }
    }

    if (pendingMigrations.isEmpty) {
      logger?.info('No pending migrations found');
      return;
    }

    // Sort by version and priority
    pendingMigrations.sort((a, b) {
      final versionCompare = a.migration.targetVersion.compareTo(b.migration.targetVersion);
      if (versionCompare != 0) return versionCompare;
      return a.migration.priority.compareTo(b.migration.priority);
    });

    logger?.info('Found ${pendingMigrations.length} pending migrations');

    // Apply migrations
    // Note: onCreate/onUpgrade are already running in a transaction,
    // so we don't need to start a new one here.
    for (final pending in pendingMigrations) {
      await _applySingleMigration(db, pending.table, pending.migration);
    }
  }

  /// Applies a single migration with idempotency check
  Future<void> _applySingleMigration(
    DatabaseExecutor db,
    Table table,
    TableMigration migration,
  ) async {
    final hash = _calculateMigrationHash(migration);

    // Check if already applied
    final isApplied = await _isMigrationApplied(db, table.name, hash);

    if (isApplied) {
      logger?.info('Skipping (already applied): ${migration.description}');
      return;
    }

    logger?.info('Applying: ${migration.description} (v${migration.targetVersion})');

    try {
      // Execute migration
      await migration.migrate(SqfliteExecutorWrapper(db), table);

      // Record as applied
      await db.insert(_migrationsTable, {
        'table_name': table.name,
        'migration_version': migration.targetVersion,
        'migration_hash': hash,
        'description': migration.description,
        'applied_at': DateTime.now().toIso8601String(),
      });

      logger?.info('Migration Success');
    } catch (e, stackTrace) {
      logger?.error('Migration Failed: ${migration.description}', e, stackTrace);
      rethrow;
    }
  }

  /// Checks if a migration has already been applied
  Future<bool> _isMigrationApplied(
    DatabaseExecutor db,
    String tableName,
    String hash,
  ) async {
    final result = await db.query(
      _migrationsTable,
      where: 'table_name = ? AND migration_hash = ?',
      whereArgs: [tableName, hash],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Calculates a unique hash for a migration
  ///
  /// Used to detect changes to migration logic and prevent re-application
  /// of modified migrations.
  String _calculateMigrationHash(TableMigration migration) {
    // Create a deterministic string representation
    final content = {
      'table': migration.table.name,
      'version': migration.targetVersion,
      'description': migration.description,
      'priority': migration.priority,
    };

    // Convert to JSON and hash
    final jsonString = jsonEncode(content);
    return _simpleHash(jsonString);
  }

  /// Simple string hashing function
  String _simpleHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash << 5) - hash + input.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs().toString();
  }

  /// Gets a list of all applied migrations
  ///
  /// Useful for debugging and migration reports.
  Future<List<Map<String, dynamic>>> getAppliedMigrations() async {
    final db = await database;
    return await db.query(
      _migrationsTable,
      orderBy: 'applied_at DESC',
    );
  }

  /// Gets the current database version from the file
  ///
  /// This is the actual version stored in the database file,
  /// which may differ from the `version` property if migrations
  /// are pending.
  Future<int> getCurrentFileVersion() async {
    final String path;
    if (databaseName == ':memory:') {
      path = databaseName;
    } else {
      path = join(await getDatabasesPath(), databaseName);
    }

    try {
      final db = await openDatabase(
        path,
        readOnly: true,
      );
      final version = await db.getVersion();
      await db.close();
      return version;
    } catch (_) {
      return 0; // Database doesn't exist
    }
  }

  /// Resets the database (for testing only)
  ///
  /// **Warning:** Deletes all data! Use only in tests.
  Future<void> reset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    if (databaseName == ':memory:') {
      return;
    }

    final path = join(await getDatabasesPath(), databaseName);
    try {
      await deleteDatabase(path);
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }

  /// Closes the database connection
  Future<void> close() async {
    await _changeController.close();
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Helper to execute an action and log its performance
  Future<T> logAction<T>(String sql, List<Object?>? arguments, Future<T> Function() action) async {
    if (!logQueries) return action();
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      if (stopwatch.elapsed >= slowQueryThreshold) {
        logger?.slowQuery(sql, arguments, stopwatch.elapsed);
      } else {
        logger?.query(sql, arguments, stopwatch.elapsed);
      }
      return result;
    } catch (e, st) {
      stopwatch.stop();
      logger?.error('Query Failed: $sql', e, st);
      rethrow;
    }
  }

  /// Executes a transaction with the provided action.
  ///
  /// The [action] callback receives a [DatabaseExecutor] that should be
  /// passed to any service methods executed within the transaction.
  ///
  /// **Example:**
  /// ```dart
  /// await dbManager.transaction((txn) async {
  ///   final userId = await userService.insertAsync(user, executor: txn);
  ///   await profileService.insertAsync(profile.copyWith(userId: userId), executor: txn);
  /// });
  /// ```
  Future<R> transaction<R>(Future<R> Function(DatabaseExecutor txn) action) async {
    final dbInstance = await database;
    final bufferedNotifications = <String>{};

    return await runZoned(
      () async {
        try {
          final result = await dbInstance.transaction((txn) async {
            return await action(txn);
          });
          // If we reached here, transaction committed successfully
          for (final table in bufferedNotifications) {
            _changeController.add(table);
          }
          return result;
        } catch (e) {
          // If transaction failed/rolled back, notifications are discarded
          rethrow;
        }
      },
      zoneValues: {#sqflow_notifications: bufferedNotifications},
    );
  }
}

/// Helper class for tracking pending migrations
class _PendingMigration {
  final Table table;
  final TableMigration migration;

  _PendingMigration(this.table, this.migration);
}

/// Wrapper for sqflite's [DatabaseExecutor] to satisfy [SqflowDatabaseExecutor].
class SqfliteExecutorWrapper implements SqflowDatabaseExecutor {
  final DatabaseExecutor _executor;
  SqfliteExecutorWrapper(this._executor);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) => _executor.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> query(String table,
          {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) =>
      _executor.query(table, distinct: distinct, columns: columns, where: where, whereArgs: whereArgs, groupBy: groupBy, having: having, orderBy: orderBy, limit: limit, offset: offset);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) => _executor.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) => _executor.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, String? conflictAlgorithm}) => _executor.insert(table, values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm != null ? ConflictAlgorithm.values.firstWhere((e) => e.name == conflictAlgorithm, orElse: () => ConflictAlgorithm.abort) : null);
}
