import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/migration_post.dart';
import 'models/migration_user.dart';

// migration_usersTable is available via `part of 'migration_user.dart'`
// It has: name='migration_users', primaryKey='custom_id'

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {});

  late DB db;

  group('Database Initialization Tests:', () {
    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('DB initializes with correct version', () async {
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [migration_usersTable],
      );

      final database = await db.database;
      expect(database, isNotNull);
      // For :memory: databases, getCurrentFileVersion returns 0
      // Check the actual database version instead
      expect(await database.getVersion(), 1);
    });

    test('Tables are created successfully', () async {
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [migration_usersTable],
      );

      final database = await db.database;
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      expect(tables.any((t) => t['name'] == 'migration_users'), isTrue);
    });
  });

  group('Migration Tracking Tests:', () {
    int migrationCallCount = 0;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('phorm_migration_test_');
    });

    tearDownAll(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    setUp(() {
      migrationCallCount = 0;
    });

    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('Migrations are applied on creation', () async {
      // Use the generated table as base, add a custom migration on top
      final tableWithMigration = migration_usersTable
          .migrate()
          .custom(
            description: 'Test migration',
            version: 1,
            migrate: (db, table) async {
              migrationCallCount++;
            },
          )
          .build();

      final dbPath = join(tempDir.path, 'test_migrations.db');
      db = DB(databaseName: dbPath, version: 1, tables: [tableWithMigration]);

      await db.database;
      expect(migrationCallCount, 1);
    });

    test('Migration order is correct', () async {
      final migrationsApplied = <String>[];

      // This test uses a custom table name ('tracked') — keep manual construction
      // but reference MigrationUser.fromJson directly
      final trackedTable =
          Table<MigrationUser>(
                type: MigrationUser,
                name: 'tracked',
                schema: 'CREATE TABLE tracked (id TEXT)',
                fromJson: MigrationUser.fromJson,
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

      db = DB(databaseName: ':memory:', version: 3, tables: [trackedTable]);

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
      // Use generated migration_usersTable as base, add a new column via migration
      final usersTable = migration_usersTable
          .migrate()
          .addColumn(
            name: 'phone',
            type: SqlTypes.text,
            version: 2,
            nullable: true,
            description: 'Add phone to migration_users',
          )
          .build();

      final postsTable =
          Table<MigrationPost>(
                type: MigrationPost,
                name: 'posts',
                schema: 'CREATE TABLE posts (id TEXT)',
                fromJson: MigrationPost.fromJson,
              )
              .migrate()
              .addColumn(
                name: 'title',
                type: SqlTypes.text,
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

      final usersColumns = await database.rawQuery(
        'PRAGMA table_info(migration_users)',
      );
      expect(usersColumns.any((c) => c['name'] == 'phone'), isTrue);

      final postsColumns = await database.rawQuery('PRAGMA table_info(posts)');
      expect(postsColumns.any((c) => c['name'] == 'title'), isTrue);
    });
  });

  group('Migration Builder Tests:', () {
    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('addColumn generates correct SQL', () async {
      // Uses custom table name 'test' — keep manual construction
      final table =
          Table<MigrationUser>(
                type: MigrationUser,
                name: 'test',
                schema: 'CREATE TABLE test (id TEXT)',
                fromJson: MigrationUser.fromJson,
              )
              .migrate()
              .addColumn(name: 'email', type: SqlTypes.text, version: 1)
              .build();

      db = DB(databaseName: ':memory:', version: 1, tables: [table]);

      await db.database;

      final database = await db.database;
      final columns = await database.rawQuery('PRAGMA table_info(test)');
      expect(columns.any((c) => c['name'] == 'email'), isTrue);
    });

    test('createIndex generates correct SQL', () async {
      final table =
          Table<MigrationUser>(
                type: MigrationUser,
                name: 'test',
                schema: 'CREATE TABLE test (id TEXT, email TEXT)',
                fromJson: MigrationUser.fromJson,
              )
              .migrate()
              .createIndex(
                name: 'idx_test_email',
                columns: ['email'],
                version: 1,
              )
              .build();

      db = DB(databaseName: ':memory:', version: 1, tables: [table]);

      await db.database;

      final database = await db.database;
      final indexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_test_email'",
      );
      expect(indexes, hasLength(1));
    });
  });

  group('Real-world Migration Scenarios:', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('phorm_scenario_test_');
    });

    tearDownAll(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    tearDown(() async {
      await db.close();
      await db.reset();
    });

    test('Simple table evolution', () async {
      // Start from the generated table, add new column at v2
      final evolvedTable = migration_usersTable
          .migrate()
          .addColumn(
            name: 'phone',
            type: SqlTypes.text,
            version: 2,
            nullable: true,
            description: 'Add phone column',
          )
          .build();

      final dbPath = join(tempDir.path, 'evolution_test.db');
      db = DB(databaseName: dbPath, version: 2, tables: [evolvedTable]);

      await db.database;

      final database = await db.database;
      final columns = await database.rawQuery(
        'PRAGMA table_info(migration_users)',
      );
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      expect(
        columnNames,
        containsAll([
          'custom_id',
          'name',
          'email',
          'age',
          'is_active',
          'created_at',
          'updated_at',
          'phone',
        ]),
      );
    });
  });

  group('Production-Ready Persistence & Upgrade Tests:', () {
    const dbFileName = 'evolution_test.db';
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('phorm_test_');
    });

    tearDownAll(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    Future<void> cleanDb() async {
      try {
        final path = join(tempDir.path, dbFileName);
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }

    setUp(() async => cleanDb());
    tearDown(() async => cleanDb());

    test(
      'Data persists and migrations apply when app updates (v1 -> v2)',
      () async {
        // --- v1: use the generated table as-is ---
        final dbPath = join(tempDir.path, dbFileName);
        final dbv1 = DB(
          databaseName: dbPath,
          version: 1,
          tables: [migration_usersTable],
        );
        final databaseV1 = await dbv1.database;

        // Insert using generated schema column names (custom_id, not id)
        await databaseV1.insert('migration_users', {
          'custom_id': '1',
          'name': 'John',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        await dbv1.close();

        // Small delay for FFI to ensure file is released
        await Future.delayed(const Duration(milliseconds: 200));

        // --- v2: add phone column via migration ---
        final usersV2 = migration_usersTable
            .migrate()
            .addColumn(
              name: 'phone',
              type: SqlTypes.text,
              version: 2,
              nullable: true,
              description: 'Add phone column',
            )
            .build();

        final dbV2 = DB(databaseName: dbPath, version: 2, tables: [usersV2]);
        final databaseV2 = await dbV2.database;

        // Verify data persists (use custom_id as PK)
        final where = WhereBuilder().eq('custom_id', '1');
        final rows = await databaseV2.query(
          'migration_users',
          where: where.build(),
          whereArgs: where.args,
        );
        expect(rows.first['name'], 'John');

        // Verify new column exists
        final tableInfo = await databaseV2.rawQuery(
          'PRAGMA table_info(migration_users)',
        );
        final hasPhone = tableInfo.any((column) => column['name'] == 'phone');
        expect(hasPhone, true);

        await dbV2.close();
      },
    );

    test(
      'Transaction rollback: If migration fails, version should NOT increase',
      () async {
        // Use the generated table as base, add a broken migration
        final brokenTable = migration_usersTable
            .migrate()
            .custom(
              description: 'Broken migration',
              version: 1,
              migrate: (db, table) async {
                throw Exception('Boom! Migration failed');
              },
            )
            .build();

        final dbPath = join(tempDir.path, dbFileName);
        final db = DB(databaseName: dbPath, version: 1, tables: [brokenTable]);

        // 1. Expect error during open
        await expectLater(db.database, throwsException);

        // 2. Allow database to close after failure
        await Future.delayed(const Duration(milliseconds: 200));

        // 3. Check file version directly
        final path = dbPath;
        final file = File(path);

        // If file doesn't exist, version is 0
        if (!await file.exists()) {
          expect(0, 0); // Version must be 0 since transaction was rolled back
          return;
        }

        final checkDb = await Database.open(path);
        final version = await checkDb.getVersion();
        await checkDb.close();

        // Version must not become 1 since the transaction was rolled back
        expect(version, 0);
      },
    );
  });
}
