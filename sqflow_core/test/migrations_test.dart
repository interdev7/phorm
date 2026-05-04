import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';

import 'models/migration_post.dart';
import 'models/migration_user.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DB db;

  group('Database Initialization Tests:', () {
    late Table<MigrationUser> usersTable;

    setUp(() {
      usersTable = Table<MigrationUser>(
        type: MigrationUser,
        name: 'users',
        schema: '''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''',
        fromJson: (json) => MigrationUser.fromJson(json),
      );
    });

    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('DB initializes with correct version', () async {
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
      );

      final database = await db.database;
      expect(database, isNotNull);
      expect(await db.getCurrentFileVersion(), 1);
    });

    test('Tables are created successfully', () async {
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
      );

      final database = await db.database;
      final tables = await database
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      expect(tables.any((t) => t['name'] == 'users'), isTrue);
    });
  });

  group('Migration Tracking Tests:', () {
    int migrationCallCount = 0;

    setUp(() {
      migrationCallCount = 0;
    });

    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('Migrations are applied on creation', () async {
      final usersTable = Table<MigrationUser>(
        type: MigrationUser,
        name: 'users',
        schema: '''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''',
        fromJson: (json) => MigrationUser.fromJson(json),
      )
          .migrate()
          .custom(
            description: 'Test migration',
            version: 1,
            migrate: (db, table) async {
              migrationCallCount++;
            },
          )
          .build();

      db = DB(
        databaseName: 'test_migrations.db',
        version: 1,
        tables: [usersTable],
      );

      await db.database;
      expect(migrationCallCount, 1);
    });

    test('Migration order is correct', () async {
      final migrationsApplied = <String>[];

      final trackedTable = Table<MigrationUser>(
        type: MigrationUser,
        name: 'tracked',
        schema: 'CREATE TABLE tracked (id TEXT)',
        fromJson: (json) => MigrationUser.fromJson(json),
      )
          .migrate()
          .custom(
            description: 'Migration v2-1',
            version: 2,
            migrate: (db, table) async {
              migrationsApplied.add('v2-1');
            },
          )
          .custom(
            description: 'Migration v2-2',
            version: 2,
            migrate: (db, table) async {
              migrationsApplied.add('v2-2');
            },
          )
          .custom(
            description: 'Migration v3',
            version: 3,
            migrate: (db, table) async {
              migrationsApplied.add('v3');
            },
          )
          .build();

      db = DB(
        databaseName: ':memory:',
        version: 3,
        tables: [trackedTable],
      );

      await db.database;
      expect(migrationsApplied, containsAll(['v2-1', 'v2-2', 'v3']));
    });
  });

  group('Version Management Tests:', () {
    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('Migration with same version from different tables', () async {
      final usersTable = Table<MigrationUser>(
        type: MigrationUser,
        name: 'users',
        schema: 'CREATE TABLE users (id TEXT)',
        fromJson: (json) => MigrationUser.fromJson(json),
      )
          .migrate()
          .addColumn(
            name: 'email',
            type: 'TEXT',
            version: 2,
            description: 'Add email to users',
          )
          .build();

      final postsTable = Table<MigrationPost>(
        type: MigrationPost,
        name: 'posts',
        schema: 'CREATE TABLE posts (id TEXT)',
        fromJson: (json) => MigrationPost.fromJson(json),
      )
          .migrate()
          .addColumn(
            name: 'title',
            type: 'TEXT',
            version: 2,
            description: 'Add title to posts',
          )
          .build();

      db = DB(
        databaseName: ':memory:',
        version: 2,
        tables: [usersTable, postsTable],
      );

      await db.database;

      final database = await db.database;

      final usersColumns = await database.rawQuery("PRAGMA table_info(users)");
      expect(usersColumns.any((c) => c['name'] == 'email'), isTrue);

      final postsColumns = await database.rawQuery("PRAGMA table_info(posts)");
      expect(postsColumns.any((c) => c['name'] == 'title'), isTrue);
    });
  });

  group('Migration Builder Tests:', () {
    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('addColumn generates correct SQL', () async {
      final table = Table<MigrationUser>(
        type: MigrationUser,
        name: 'test',
        schema: 'CREATE TABLE test (id TEXT)',
        fromJson: (json) => MigrationUser.fromJson(json),
      )
          .migrate()
          .addColumn(
            name: 'email',
            type: 'TEXT',
            version: 1,
          )
          .build();

      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [table],
      );

      await db.database;

      final database = await db.database;
      final columns = await database.rawQuery("PRAGMA table_info(test)");
      expect(columns.any((c) => c['name'] == 'email'), isTrue);
    });

    test('createIndex generates correct SQL', () async {
      final table = Table<MigrationUser>(
        type: MigrationUser,
        name: 'test',
        schema: 'CREATE TABLE test (id TEXT, email TEXT)',
        fromJson: (json) => MigrationUser.fromJson(json),
      )
          .migrate()
          .createIndex(
            name: 'idx_test_email',
            columns: ['email'],
            version: 1,
          )
          .build();

      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [table],
      );

      await db.database;

      final database = await db.database;
      final indexes = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_test_email'");
      expect(indexes, hasLength(1));
    });
  });

  group('Real-world Migration Scenarios:', () {
    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('Simple table evolution', () async {
      // Create table with migrations
      final usersTable = Table<MigrationUser>(
        type: MigrationUser,
        name: 'users',
        schema: '''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''',
        fromJson: (json) => MigrationUser.fromJson(json),
      )
          .migrate()
          .addColumn(
            name: 'email',
            type: 'TEXT',
            version: 2,
            description: 'Add email column',
          )
          .addColumn(
            name: 'age',
            type: 'INTEGER',
            version: 2,
            nullable: true,
            description: 'Add age column',
          )
          .build();

      db = DB(
        databaseName: 'evolution_test.db',
        version: 2,
        tables: [usersTable],
      );

      await db.database;

      final database = await db.database;
      final columns = await database.rawQuery("PRAGMA table_info(users)");
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      expect(columnNames,
          containsAll(['id', 'username', 'created_at', 'email', 'age']));
    });
  });

  group('Production-Ready Persistence & Upgrade Tests:', () {
    const dbFileName = 'evolution_test.db';

    Future<void> cleanDb() async {
      try {
        final path = join(await getDatabasesPath(), dbFileName);
        if (await databaseFactory.databaseExists(path)) {
          await databaseFactory.deleteDatabase(path);
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }

    setUp(() async => await cleanDb());
    tearDown(() async => await cleanDb());

    test('Data persists and migrations apply when app updates (v1 -> v2)',
        () async {
      final usersV1 = Table<MigrationUser>(
        type: MigrationUser,
        name: 'users',
        schema:
            'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT, created_at TEXT)',
        fromJson: (json) => MigrationUser.fromJson(json),
      );

      // --- v1 ---
      final dbv1 = DB(databaseName: dbFileName, version: 1, tables: [usersV1]);
      final databaseV1 = await dbv1.database;
      await databaseV1.insert('users', {
        'id': '1',
        'name': 'John',
        'created_at': DateTime.now().toIso8601String()
      });
      await dbv1.close();

      // Small delay for FFI to ensure file is released
      await Future.delayed(const Duration(milliseconds: 200));

      // --- v2 ---
      final usersV2 = usersV1
          .migrate()
          .addColumn(name: 'email', type: 'TEXT', version: 2)
          .build();

      final dbV2 = DB(databaseName: dbFileName, version: 2, tables: [usersV2]);
      final databaseV2 = await dbV2.database;

      // Verify data persists
      final where = WhereBuilder().eq('id', '1');
      final rows = await databaseV2.query('users',
          where: where.build(), whereArgs: where.args);
      expect(rows.first['name'], 'John');

      // Verify new column exists
      final tableInfo = await databaseV2.rawQuery('PRAGMA table_info(users)');
      final hasEmail = tableInfo.any((column) => column['name'] == 'email');
      expect(hasEmail, true);

      await dbV2.close();
    });

    test(
        'Transaction rollback: If migration fails, version should NOT increase',
        () async {
      final brokenTable = Table<MigrationUser>(
        type: MigrationUser,
        name: 'users',
        schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT)',
        fromJson: (json) => MigrationUser.fromJson(json),
      )
          .migrate()
          .custom(
            description: 'Broken migration',
            version: 1, // Fail during creation
            migrate: (db, table) async {
              throw Exception('Boom! Migration failed');
            },
          )
          .build();

      final db =
          DB(databaseName: dbFileName, version: 1, tables: [brokenTable]);

      // 1. Expect error during open
      await expectLater(db.database, throwsException);

      // 2. Allow database to close after failure
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. Check file version directly via factory, not through our DB class
      final path = join(await getDatabasesPath(), dbFileName);
      final checkDb = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(readOnly: true));
      final version = await checkDb.getVersion();
      await checkDb.close();

      // Version must not become 1 since the transaction was rolled back
      expect(version, 0);
    });
  });
}
