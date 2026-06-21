// =======================================================
// DATABASE SERVICE WITH SMART MIGRATIONS 🚀
// =======================================================
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phorm/phorm.dart';

import 'database_adapter.dart';
import 'sql_function.dart';
import 'sqlite_dialect.dart';

/// Gets the database directory path
Future<String> getDatabasesPath() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, 'databases');
  } else {
    return '.';
  }
}

/// Main database manager that handles connection lifecycle,
/// version management, and smart migration tracking for SQLite.
class DB implements PhormDatabase {
  /// Database file name (e.g., 'app_database.db')
  final String databaseName;

  /// Current database schema version
  /// Must be >= highest migration version across all tables
  final int version;

  /// List of table configurations including schemas and migrations
  @override
  final List<Table> tables;

  /// Custom SQL functions to register with the database
  final List<SqlFunction> customFunctions;

  /// Optional password for SQLCipher encryption (Native only)
  final String? password;

  /// Internal database instance (lazy-loaded)
  Database? _database;

  /// Guards concurrent calls to [database] getter — prevents double-init race condition.
  Completer<Database>? _initCompleter;

  /// Name of the migrations tracking table
  static const String _migrationsTable = '__phorm_migrations';

  /// Optional logger for the database
  @override
  final PhormLogger? logger;

  /// Whether to log all queries
  final bool logQueries;

  /// Threshold for logging slow queries
  final Duration slowQueryThreshold;

  /// Whether to use a single instance for the same database path.
  /// Set to false for in-memory databases in tests to ensure isolation.
  final bool singleInstance;

  /// Row count threshold at which data mapping is moved to an isolate.
  /// Default is 50 rows.
  @override
  final int isolateThreshold;

  /// Internal stream controller for table changes
  final _changeController = StreamController<String>.broadcast();

  /// Subscription to background database change events
  StreamSubscription<String>? _dbChangeSubscription;

  /// Stream of table names that have been modified
  @override
  Stream<String> get changeStream => _changeController.stream;

  /// Active transaction buffer for updatesSync events.
  Set<String>? _activeTransactionBuffer;

  @override
  SqlDialect get dialect => SqliteDialect();

  /// Notifies the database that a table has been modified.
  /// If inside a transaction, notifications are buffered and emitted after commit.
  void notifyTableChange(String tableName) {
    if (_activeTransactionBuffer != null) {
      _activeTransactionBuffer!.add(tableName);
    } else {
      _changeController.add(tableName);
    }
  }

  DB({
    required this.version,
    required this.tables,
    this.databaseName = 'app_database.db',
    this.customFunctions = const [],
    this.password,
    this.logger = const PhormConsoleLogger(),
    this.logQueries = false,
    this.slowQueryThreshold = const Duration(milliseconds: 200),
    this.singleInstance = true,
    this.isolateThreshold = 50,
  }) {
    _validateMigrations();
  }

  /// Creates a database with auto-detected version
  factory DB.autoVersion({
    required String databaseName,
    required List<Table> tables,
    List<SqlFunction> customFunctions = const [],
    String? password,
    PhormLogger? logger = const PhormConsoleLogger(),
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
      customFunctions: customFunctions,
      password: password,
      logger: logger,
      logQueries: logQueries,
      slowQueryThreshold: slowQueryThreshold,
      singleInstance: singleInstance,
      isolateThreshold: isolateThreshold,
    );
  }

  /// Gets the database instance (lazy initialization).
  /// Thread-safe: concurrent callers all await the same Completer.
  Future<Database> get database async {
    if (_database != null) return _database!;

    // If initialization is already in progress, wait for it to complete.
    if (_initCompleter != null) return _initCompleter!.future;

    final completer = Completer<Database>();
    _initCompleter = completer;

    // Start initialization asynchronously to ensure the caller is registered
    // as a listener on the returned future before any errors can be thrown.
    unawaited(() async {
      try {
        final db = await _initDatabase();
        _database = db;
        completer.complete(db);
      } catch (e, st) {
        _initCompleter = null;
        completer.completeError(e, st);
      }
    }());

    return completer.future;
  }

  @override
  Future<DatabaseExecutor> get executor async => database;

  /// Initializes the database connection
  Future<Database> _initDatabase() async {
    final String path;
    if (databaseName == ':memory:') {
      path = ':memory:';
    } else if (databaseName.startsWith('/') || databaseName.contains(':\\')) {
      // Absolute path provided
      path = databaseName;
    } else {
      // Relative path - use getDatabasesPath
      path = join(await getDatabasesPath(), databaseName);
    }

    logger?.info('Initializing database: $databaseName (v$version)');

    final db = await Database.open(
      path,
      customFunctions: customFunctions,
      password: password,
    );

    try {
      // Cancel old subscription if any and subscribe to database changeStream
      await _dbChangeSubscription?.cancel();
      _dbChangeSubscription = db.changeStream.listen((tableName) {
        notifyTableChange(tableName);
      });

      await _onConfigure(db);

      final currentVersion = await db.getVersion();

      if (currentVersion == 0) {
        await _onCreate(db, version);
        await db.setVersion(version);
      } else if (currentVersion < version) {
        await _onUpgrade(db, currentVersion, version);
        await db.setVersion(version);
      } else if (currentVersion > version) {
        await _onDowngrade(db, currentVersion, version);
        await db.setVersion(version);
      }

      return db;
    } catch (e) {
      // Close the database to release resources on failure
      await db.close();
      rethrow;
    }
  }

  /// Validates that all migrations are within the database version
  void _validateMigrations() {
    for (final table in tables) {
      for (final migration in table.migrations) {
        if (migration.targetVersion > version) {
          throw ArgumentError(
            'Table "${table.name}" has migration "${migration.description}" '
            'for version ${migration.targetVersion}, but database version is $version. '
            'Either increase database version or remove the migration.',
          );
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
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    logger?.info('Downgrading database from v$oldVersion to v$newVersion');

    // Close current connection
    await db.close();

    // Delete database file
    if (databaseName != ':memory:') {
      final path = join(await getDatabasesPath(), databaseName);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
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
    Database db,
    int fromVersion,
    int toVersion,
  ) async {
    // Collect all migrations in the version range
    final pendingMigrations = <_PendingMigration>[];

    for (final table in tables) {
      for (final migration in table.migrations) {
        if (migration.targetVersion > fromVersion &&
            migration.targetVersion <= toVersion) {
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
      final versionCompare = a.migration.targetVersion.compareTo(
        b.migration.targetVersion,
      );
      if (versionCompare != 0) return versionCompare;
      return a.migration.priority.compareTo(b.migration.priority);
    });

    logger?.info('Found ${pendingMigrations.length} pending migrations');

    // Apply migrations in a transaction
    await db.transaction((txn) async {
      for (final pending in pendingMigrations) {
        await _applySingleMigration(db, pending.table, pending.migration);
      }
    });
  }

  /// Applies a single migration with idempotency check
  Future<void> _applySingleMigration(
    Database db,
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

    logger?.info(
      'Applying: ${migration.description} (v${migration.targetVersion})',
    );

    try {
      // Execute migration
      await migration.migrate(PhormDatabaseExecutorWrapper(db), table);

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
      logger?.error(
        'Migration Failed: ${migration.description}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Checks if a migration has already been applied
  Future<bool> _isMigrationApplied(
    Database db,
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
  Future<List<Map<String, dynamic>>> getAppliedMigrations() async {
    final db = await database;
    return await db.query(_migrationsTable, orderBy: 'applied_at DESC');
  }

  /// Gets the current database version from the file
  Future<int> getCurrentFileVersion() async {
    final String path;
    if (databaseName == ':memory:') {
      return 0;
    } else {
      path = join(await getDatabasesPath(), databaseName);
    }

    try {
      final file = File(path);
      if (!await file.exists()) return 0;

      final db = await Database.open(path);
      final version = await db.getVersion();
      await db.close();
      return version;
    } catch (_) {
      return 0; // Database doesn't exist
    }
  }

  /// Resets the database (for testing only)
  Future<void> reset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _initCompleter = null;

    if (databaseName == ':memory:') {
      return;
    }

    // Check if it's an absolute path
    final String path;
    if (databaseName.startsWith('/') || databaseName.contains(':\\')) {
      path = databaseName;
    } else {
      path = join(await getDatabasesPath(), databaseName);
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }

  /// Closes the database connection
  @override
  Future<void> close() async {
    await _changeController.close();
    await _dbChangeSubscription?.cancel();
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _initCompleter = null;
  }

  /// Executes a list of seeders to populate the database.
  Future<void> seed(List<Seeder> seeders) async {
    logger?.info('Starting database seeding (${seeders.length} seeders)...');
    for (final seeder in seeders) {
      logger?.info('Running seeder: ${seeder.runtimeType}');
      await seeder.run(this);
    }
    logger?.info('Seeding completed successfully');
  }

  /// Helper to execute an action and log its performance
  @override
  Future<T> logAction<T>(
    String sql,
    List<Object?>? arguments,
    Future<T> Function() action,
  ) async {
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
  @override
  Future<R> transaction<R>(
    Future<R> Function(DatabaseExecutor txn) action,
  ) async {
    final dbInstance = await database;

    final isTopLevel = _activeTransactionBuffer == null;
    if (isTopLevel) {
      _activeTransactionBuffer = <String>{};
    }

    try {
      final result = await dbInstance.transaction((txn) async {
        return await action(txn);
      });

      if (isTopLevel) {
        final buffered = _activeTransactionBuffer;
        _activeTransactionBuffer = null;
        if (buffered != null) {
          for (final table in buffered) {
            _changeController.add(table);
          }
        }
      }
      return result;
    } catch (e) {
      if (isTopLevel) {
        _activeTransactionBuffer = null; // discard on rollback
      }
      rethrow;
    }
  }
}

/// Helper class for tracking pending migrations
class _PendingMigration {
  final Table table;
  final TableMigration migration;

  _PendingMigration(this.table, this.migration);
}

/// Wrapper for Database to satisfy [PhormDatabaseExecutor].
class PhormDatabaseExecutorWrapper implements PhormDatabaseExecutor {
  final Database _executor;
  PhormDatabaseExecutorWrapper(this._executor);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _executor.execute(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) => _executor.query(
    table,
    distinct: distinct,
    columns: columns,
    where: where,
    whereArgs: whereArgs,
    groupBy: groupBy,
    having: having,
    orderBy: orderBy,
    limit: limit,
    offset: offset,
  );

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _executor.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) => _executor.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    String? conflictAlgorithm,
  }) => _executor.insert(
    table,
    values,
    nullColumnHack: nullColumnHack,
    conflictAlgorithm:
        conflictAlgorithm != null
            ? ConflictAlgorithm.values.firstWhere(
              (e) => e.name == conflictAlgorithm,
              orElse: () => ConflictAlgorithm.abort,
            )
            : null,
  );
}
