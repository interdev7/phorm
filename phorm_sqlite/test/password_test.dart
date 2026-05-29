import 'dart:io';
import 'package:path/path.dart' as p;
import 'models/collation_model.dart';
import 'test_utils.dart';

void main() {
  group('Database Password/Encryption Flow', () {
    late String dbPath;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('phorm_password_test');
      dbPath = p.join(tempDir.path, 'encrypted.db');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Should open database with password and perform basic CRUD', () async {
      // 1. Initialize DB with a password
      final db = DB(
        databaseName: dbPath,
        version: 1,
        password: 'super_secret_password_123',
        tables: [collation_testsTable],
        singleInstance: false,
      );

      final service = PhormCore<CollationTest>(
        dbManager: db,
        table: collation_testsTable,
      );

      // 2. Insert a row
      await service.insert(CollationTest(
        id: '1',
        nameNoCase: 'Alice',
        nameBinary: 'Alice',
      ));

      // 3. Read it back
      final listBeforeClose = await service.readAll();
      expect(listBeforeClose.data.length, 1);
      expect(listBeforeClose.data.first.nameNoCase, 'Alice');

      // 4. Close the database connection
      final dbInstance = await db.database;
      await dbInstance.close();

      // 5. Re-open with the same password and verify data persists
      final dbReopened = DB(
        databaseName: dbPath,
        version: 1,
        password: 'super_secret_password_123',
        tables: [collation_testsTable],
        singleInstance: false,
      );

      final serviceReopened = PhormCore<CollationTest>(
        dbManager: dbReopened,
        table: collation_testsTable,
      );

      final listAfterReopen = await serviceReopened.readAll();
      expect(listAfterReopen.data.length, 1);
      expect(listAfterReopen.data.first.nameNoCase, 'Alice');

      // Cleanup
      final dbInstanceReopened = await dbReopened.database;
      await dbInstanceReopened.close();
    });

    test(
        'Should fail to read when opened with incorrect password (if SQLCipher is supported)',
        () async {
      // 1. Initialize DB with a password
      final db = DB(
        databaseName: dbPath,
        version: 1,
        password: 'correct_password_123',
        tables: [collation_testsTable],
        singleInstance: false,
      );

      final service = PhormCore<CollationTest>(
        dbManager: db,
        table: collation_testsTable,
      );

      // 2. Insert a row to ensure database is created and written
      await service.insert(CollationTest(
        id: '1',
        nameNoCase: 'Alice',
        nameBinary: 'Alice',
      ));

      // 3. Close the database
      final dbInstance = await db.database;

      // Detect if SQLCipher is actually supported in the current test environment
      final cipherCheck = await dbInstance.rawQuery('PRAGMA cipher_version');
      final isSqlCipherSupported = cipherCheck.isNotEmpty &&
          cipherCheck.first.values.first != null &&
          (cipherCheck.first.values.first as String).isNotEmpty;

      await dbInstance.close();

      // 4. Attempt to open with WRONG password
      final dbWrongPassword = DB(
        databaseName: dbPath,
        version: 1,
        password: 'wrong_password_xyz',
        tables: [collation_testsTable],
        singleInstance: false,
      );

      if (isSqlCipherSupported) {
        // If SQLCipher is active, reading should fail with SqliteException (usually code 26 - SQLITE_NOTADB)
        expect(
          () async {
            final serviceWrong = PhormCore<CollationTest>(
              dbManager: dbWrongPassword,
              table: collation_testsTable,
            );
            await serviceWrong.readAll();
          },
          throwsA(isA<Exception>()),
          reason:
              'SQLCipher is active; opening with the wrong password must fail.',
        );
      } else {
        // If standard SQLite (no SQLCipher), PRAGMA key is a no-op, so it opens and reads normally
        final serviceWrong = PhormCore<CollationTest>(
          dbManager: dbWrongPassword,
          table: collation_testsTable,
        );
        final list = await serviceWrong.readAll();
        expect(list.data.length, 1,
            reason: 'Standard SQLite ignores PRAGMA key, so reading succeeds.');

        final dbInstanceWrong = await dbWrongPassword.database;
        await dbInstanceWrong.close();
      }
    });
  });
}
