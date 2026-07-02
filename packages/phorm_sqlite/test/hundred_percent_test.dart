import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('synchronizeHistory records unseen migrations', () {
    test('inserts a synced record when the migration is not yet tracked',
        () async {
      final table = usersTable
          .migrate()
          .custom(
            description: 'tracked later',
            version: 2,
            migrate: (db, table) async {},
          )
          .build();
      final db = DB(
        databaseName: ':memory:',
        version: 2,
        tables: [table],
        singleInstance: false,
      );
      final raw = await db.database;
      // _onCreate already recorded the migration; clear it so
      // synchronizeHistory hits its insert (exists.isEmpty) branch.
      await raw.execute('DELETE FROM __phorm_migrations');
      await db.synchronizeHistory();
      final applied = await db.getAppliedMigrations();
      expect(
        applied.any((m) => '${m['description']}'.contains('(Synced)')),
        isTrue,
      );
      await db.close();
    });
  });

  group('CHECK constraint name ending in _check', () {
    test('strips the _check suffix when no value matches the constraint',
        () async {
      final db = await Database.open(':memory:');
      // Constraint name ends with `_check`; the failing insert uses a column
      // that is NOT part of the constraint name, so the fallback cleaner runs
      // and strips the `_check` suffix.
      await db.execute(
        'CREATE TABLE c (id INTEGER PRIMARY KEY, status TEXT, '
        "CONSTRAINT status_check CHECK (status IN ('a','b')))",
      );
      await expectLater(
        db.rawQuery("INSERT INTO c (id, status) VALUES (1, 'zzz')"),
        throwsA(isA<PhormCHECKValidatorException>()),
      );
      await db.close();
    });
  });

  group('DB file-backed lifecycle branches', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('phorm_100_test_');
      await Directory(join(tempDir.path, 'databases')).create(recursive: true);
      Future<Object?> handler(MethodCall call) async => tempDir.path;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        handler,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider_macos'),
        handler,
      );
    });

    tearDownAll(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    Future<void> cleanup(String name) async {
      final f = File(join(tempDir.path, 'databases', name));
      if (await f.exists()) await f.delete();
    }

    test('upgrade re-runs IF NOT EXISTS statements for existing tables',
        () async {
      const name = 'idempotent.db';
      await cleanup(name);

      Table<User> pivotTable(String pivotName) => Table<User>(
            type: User,
            name: 'users',
            schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT);'
                'CREATE TABLE IF NOT EXISTS $pivotName '
                '(user_id TEXT NOT NULL, role_id TEXT NOT NULL, '
                'PRIMARY KEY (user_id, role_id));',
            fromJson: User.fromJson,
            columns: const ['id', 'name'],
          );

      // v1 with users + pivot.
      final v1 = DB(databaseName: name, version: 1, tables: [pivotTable('ur')]);
      await v1.database;
      await v1.close();

      // v2: users table already exists → else branch calls
      // _ensureIdempotentSchemaObjects, which re-executes the IF NOT EXISTS
      // pivot statement (target != table.name → log + execute).
      final v2 = DB(databaseName: name, version: 2, tables: [pivotTable('ur')]);
      final db = await v2.database;
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='ur'",
      );
      expect(rows, isNotEmpty);
      await v2.close();
      await cleanup(name);
    });

    test('a table with an invalid schema surfaces the create error', () async {
      const name = 'broken.db';
      await cleanup(name);

      final broken = Table<User>(
        type: User,
        name: 'broken',
        schema: 'CREATE TABLE broken (this is not valid sql',
        fromJson: User.fromJson,
        columns: const ['id'],
      );
      final db = DB(databaseName: name, version: 1, tables: [broken]);
      await expectLater(db.database, throwsA(isA<Object>()));
      await cleanup(name);
    });

    test('already-applied migrations are skipped on upgrade', () async {
      const name = 'skip_migration.db';
      await cleanup(name);

      Table<User> withMigration() => usersTable
          .migrate()
          .custom(
            description: 'v2 change',
            version: 2,
            migrate: (db, table) async {},
          )
          .build();

      // Create at v2 → _onCreate applies & records the v2 migration.
      final first = DB(databaseName: name, version: 2, tables: [withMigration()]);
      final raw = await first.database;
      // Roll the file's user_version back to 1 while keeping the migration
      // record, so the next open takes the upgrade path onto an
      // already-applied migration.
      await raw.setVersion(1);
      await first.close();

      // Reopen at v2 → currentVersion(1) < 2 → _onUpgrade →
      // _applyPendingMigrations selects the v2 migration, which is already
      // recorded by hash → _applySingleMigration takes the skip branch.
      final v2 = DB(databaseName: name, version: 2, tables: [withMigration()]);
      await v2.database;
      final applied = await v2.getAppliedMigrations();
      expect(
        applied.any((m) => '${m['description']}'.contains('v2 change')),
        isTrue,
      );
      await v2.close();
      await cleanup(name);
    });
  });
}
