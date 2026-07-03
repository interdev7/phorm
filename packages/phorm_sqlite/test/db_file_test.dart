import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('phorm_db_file_test_');
    // getDatabasesPath() appends a 'databases' subdir on desktop platforms.
    await Directory(join(tempDir.path, 'databases')).create(recursive: true);
    // Mock the path_provider platform channel so getDatabasesPath() works
    // in the unit-test environment (no real plugin).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider_macos'),
          (call) async => tempDir.path,
        );
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('getDatabasesPath resolves a non-empty path', () async {
    final path = await getDatabasesPath();
    expect(path, isNotEmpty);
  });

  test('relative database name resolves via getDatabasesPath', () async {
    final db = DB(
      databaseName: 'relative_app.db',
      version: 1,
      tables: [usersTable],
    );
    final instance = await db.database;
    expect(instance, isA<Database>());
    await db.close();
    await db.reset(); // relative-path reset branch
  });

  test('getCurrentFileVersion reads version from an existing file', () async {
    final db = DB(
      databaseName: 'versioned.db',
      version: 1,
      tables: [usersTable],
    );
    await db.database;
    await db.close();

    final version = await db.getCurrentFileVersion();
    expect(version, 1);

    await db.reset();
    // Now the file is gone → returns 0.
    expect(await db.getCurrentFileVersion(), 0);
  });

  test('upgrade creates newly-added tables', () async {
    final dbName = 'lifecycle.db';

    // v1: only users table.
    final v1 = DB(databaseName: dbName, version: 1, tables: [usersTable]);
    await v1.database;
    await v1.close();

    // v2: add a brand-new table → _onUpgrade "new table detected" path.
    final extraTable = Table<User>(
      type: User,
      name: 'extra_things',
      schema: 'CREATE TABLE extra_things (id INTEGER PRIMARY KEY)',
      fromJson: User.fromJson,
    );
    final v2 = DB(
      databaseName: dbName,
      version: 2,
      tables: [usersTable, extraTable],
    );
    final upgraded = await v2.database;
    final tables = await upgraded.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='extra_things'",
    );
    expect(tables, isNotEmpty);
    await v2.close();
    await v2.reset();

    // Clean up any leftover file.
    final f = File(join(tempDir.path, 'databases', dbName));
    if (await f.exists()) await f.delete();
  });
}
