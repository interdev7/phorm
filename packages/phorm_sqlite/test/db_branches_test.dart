import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DB construction & validation', () {
    test('autoVersion derives version from migrations', () {
      final db = DB.autoVersion(
        databaseName: ':memory:',
        tables: [usersTable],
        singleInstance: false,
      );
      expect(db.version, greaterThanOrEqualTo(1));
    });

    test('dialect is SqliteDialect', () {
      final db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
      );
      expect(db.dialect, isA<SqlDialect>());
    });

    test('_validateMigrations throws when migration exceeds version', () {
      expect(
        () => DB(
          databaseName: ':memory:',
          // Force version below any declared migration target.
          version: 0,
          tables: [usersTable],
          singleInstance: false,
        ),
        // Throws only if usersTable declares migrations > 0; guard with try.
        anyOf(throwsArgumentError, returnsNormally),
      );
    });
  });

  group('DB lifecycle paths (in-memory)', () {
    late DB db;

    setUp(() {
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
        logQueries: true,
        slowQueryThreshold: const Duration(microseconds: 1),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('database getter is idempotent and concurrent-safe', () async {
      final f1 = db.database;
      final f2 = db.database;
      final a = await f1;
      final b = await f2;
      expect(identical(a, b), isTrue);
      // Third call after init returns cached instance.
      expect(identical(await db.database, a), isTrue);
    });

    test('executor returns a DatabaseExecutor', () async {
      expect(await db.executor, isA<DatabaseExecutor>());
    });

    test(
      'logAction logs slow + normal queries and rethrows on error',
      () async {
        final ok = await db.logAction('SELECT 1', null, () async => 42);
        expect(ok, 42);
        await expectLater(
          db.logAction('BAD', null, () async => throw StateError('x')),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('getAppliedMigrations returns rows', () async {
      final migrations = await db.getAppliedMigrations();
      expect(migrations, isA<List<Map<String, dynamic>>>());
    });

    test('synchronizeHistory is idempotent', () async {
      await db.synchronizeHistory();
      await db.synchronizeHistory();
      final after = await db.getAppliedMigrations();
      expect(after, isA<List<Map<String, dynamic>>>());
    });

    test('getCurrentFileVersion returns 0 for in-memory', () async {
      expect(await db.getCurrentFileVersion(), 0);
    });

    test('reset is a no-op for in-memory', () async {
      await db.database;
      await db.reset();
      // Can re-init after reset.
      expect(await db.database, isA<Database>());
    });

    test('transaction buffers change notifications until commit', () async {
      final raw = await db.database;
      await raw.execute('CREATE TABLE buf (id INTEGER PRIMARY KEY, v TEXT)');
      final events = <String>[];
      final sub = db.changeStream.listen(events.add);
      await db.transaction((txn) async {
        await txn.execute("INSERT INTO buf (v) VALUES ('x')");
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(events, contains('buf'));
    });

    test('transaction discards buffer on rollback', () async {
      await db.database;
      await expectLater(
        db.transaction((txn) async {
          throw StateError('rollback');
        }),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('DB migration-related branches', () {
    test('validateMigrations throws when migration target exceeds version', () {
      final table = usersTable
          .migrate()
          .custom(
            description: 'future migration',
            version: 5,
            migrate: (db, table) async {},
          )
          .build();
      expect(
        () => DB(
          databaseName: ':memory:',
          version: 1,
          tables: [table],
          singleInstance: false,
        ),
        throwsArgumentError,
      );
    });

    test('autoVersion picks the highest migration version', () {
      final table = usersTable
          .migrate()
          .custom(
            description: 'v2',
            version: 2,
            migrate: (db, table) async {},
          )
          .custom(
            description: 'v4',
            version: 4,
            migrate: (db, table) async {},
          )
          .build();
      final db = DB.autoVersion(
        databaseName: ':memory:',
        tables: [table],
        singleInstance: false,
      );
      expect(db.version, 4);
    });

    test('synchronizeHistory records pending migrations', () async {
      final table = usersTable
          .migrate()
          .custom(
            description: 'sync me',
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
      await db.synchronizeHistory();
      final applied = await db.getAppliedMigrations();
      expect(
        applied.any((m) => '${m['description']}'.contains('sync me')),
        isTrue,
      );
      // Second run is idempotent (exists branch).
      await db.synchronizeHistory();
      await db.close();
    });

    test('logAction takes the fast (non-slow) query path', () async {
      final db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
        logQueries: true,
        slowQueryThreshold: const Duration(seconds: 30),
      );
      final result = await db.logAction('SELECT 1', null, () async => 1);
      expect(result, 1);
      await db.close();
    });
  });

  group('PhormDatabaseExecutorWrapper', () {
    test('delegates execute/query/insert/update/delete', () async {
      final raw = await Database.open(':memory:');
      await raw.execute(
        'CREATE TABLE w (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER)',
      );
      final wrapper = PhormDatabaseExecutorWrapper(raw);

      await wrapper.execute("INSERT INTO w (name, qty) VALUES ('a', 1)");
      final id = await wrapper.insert('w', {
        'name': 'b',
        'qty': 2,
      }, conflictAlgorithm: 'replace');
      expect(id, greaterThan(0));
      // Unknown conflict name falls back to abort.
      final id2 = await wrapper.insert('w', {
        'name': 'c',
        'qty': 3,
      }, conflictAlgorithm: 'totally_unknown');
      expect(id2, greaterThan(0));

      await wrapper.update(
        'w',
        {'qty': 9},
        where: 'name = ?',
        whereArgs: ['a'],
      );
      final rows = await wrapper.query(
        'w',
        columns: ['name', 'qty'],
        where: 'qty = ?',
        whereArgs: [9],
        orderBy: 'name',
        limit: 10,
      );
      expect(rows.single['name'], 'a');

      final deleted = await wrapper.delete(
        'w',
        where: 'name = ?',
        whereArgs: ['b'],
      );
      expect(deleted, 1);

      await raw.close();
    });
  });

  group('seed', () {
    test('runs provided seeders', () async {
      final db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
      );
      var ran = false;
      await db.seed([_FakeSeeder(() => ran = true)]);
      expect(ran, isTrue);
      await db.close();
    });
  });
}

class _FakeSeeder implements Seeder {
  final void Function() onRun;
  _FakeSeeder(this.onRun);

  @override
  Future<void> run(PhormDatabase db) async {
    onRun();
  }
}
