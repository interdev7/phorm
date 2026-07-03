import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'package:phorm_sqlite/src/database_isolate_common.dart';
import 'package:phorm_sqlite/src/database_isolate_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database adapter — query builder clauses', () {
    late Database db;

    setUp(() async {
      db = await Database.open(':memory:');
      await db.execute(
        'CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER)',
      );
      await db.execute("INSERT INTO items (name, qty) VALUES ('a', 1)");
      await db.execute("INSERT INTO items (name, qty) VALUES ('a', 2)");
      await db.execute("INSERT INTO items (name, qty) VALUES ('b', 3)");
    });

    tearDown(() => db.close());

    test(
      'exercises distinct/where/groupBy/having/orderBy/limit/offset',
      () async {
        final rows = await db.query(
          'items',
          distinct: true,
          columns: ['name', 'COUNT(*) as c'],
          where: 'qty > ?',
          whereArgs: [0],
          groupBy: 'name',
          having: 'COUNT(*) >= 1',
          orderBy: 'name DESC',
          limit: 5,
          offset: 0,
        );
        expect(rows, isNotEmpty);
      },
    );

    test('rawQuery returns rows', () async {
      final rows = await db.rawQuery('SELECT * FROM items WHERE qty = ?', [3]);
      expect(rows.single['name'], 'b');
    });

    test('insert with conflictAlgorithm + update + delete', () async {
      final id = await db.insert('items', {
        'name': 'c',
        'qty': 4,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      expect(id, greaterThan(0));

      final updated = await db.update(
        'items',
        {'qty': 99},
        where: 'name = ?',
        whereArgs: ['c'],
      );
      expect(updated, 1);

      final deleted = await db.delete(
        'items',
        where: 'name = ?',
        whereArgs: ['c'],
      );
      expect(deleted, 1);
    });

    test('getVersion / setVersion', () async {
      await db.setVersion(7);
      expect(await db.getVersion(), 7);
    });
  });

  group('Database adapter — Transaction wrapper', () {
    late Database db;

    setUp(() async {
      db = await Database.open(':memory:');
      await db.execute(
        'CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER)',
      );
    });

    tearDown(() => db.close());

    test('all Transaction delegating methods', () async {
      await db.transaction((txn) async {
        await txn.execute("INSERT INTO t (name, qty) VALUES ('x', 1)");
        await txn.rawQuery('SELECT * FROM t');
        final id = await txn.insert('t', {'name': 'y', 'qty': 2});
        expect(id, greaterThan(0));
        await txn.update('t', {'qty': 5}, where: 'name = ?', whereArgs: ['y']);
        final rows = await txn.query(
          't',
          distinct: false,
          columns: ['name'],
          where: 'qty = ?',
          whereArgs: [5],
          orderBy: 'name',
          limit: 1,
        );
        expect(rows, isNotEmpty);
        await txn.delete('t', where: 'name = ?', whereArgs: ['x']);
        // Transaction.batch() delegates to the db batch (build only here).
        final b = txn.batch();
        expect(b, isA<Batch>());
      });
      final all = await db.query('t');
      expect(all.map((r) => r['name']), contains('y'));
    });

    test('transaction rolls back on error', () async {
      await expectLater(
        db.transaction((txn) async {
          await txn.execute("INSERT INTO t (name, qty) VALUES ('rb', 1)");
          throw StateError('boom');
        }),
        throwsA(isA<StateError>()),
      );
      final rows = await db.query('t', where: 'name = ?', whereArgs: ['rb']);
      expect(rows, isEmpty);
    });
  });

  group('Database adapter — Batch', () {
    late Database db;

    setUp(() async {
      db = await Database.open(':memory:');
      await db.execute(
        'CREATE TABLE b (id INTEGER PRIMARY KEY, name TEXT UNIQUE, qty INTEGER)',
      );
    });

    tearDown(() => db.close());

    test('insert/update/delete/execute/raw* operations commit', () async {
      final batch = db.batch()
        ..insert('b', {'name': 'one', 'qty': 1})
        ..insert('b', {
          'name': 'two',
          'qty': 2,
        }, conflictAlgorithm: ConflictAlgorithm.replace)
        ..rawInsert("INSERT INTO b (name, qty) VALUES ('three', 3)")
        ..update('b', {'qty': 10}, where: 'name = ?', whereArgs: ['one'])
        ..rawUpdate("UPDATE b SET qty = 20 WHERE name = 'two'")
        ..execute("UPDATE b SET qty = qty + 1 WHERE name = 'three'")
        ..delete('b', where: 'name = ?', whereArgs: ['nope'])
        ..rawDelete("DELETE FROM b WHERE name = 'missing'");
      final results = await batch.commit();
      expect(results, isNotEmpty);

      final rows = await db.query('b', orderBy: 'name');
      expect(rows.length, 3);
    });

    test('commit with noResult returns empty list', () async {
      final batch = db.batch()..insert('b', {'name': 'nr', 'qty': 1});
      final results = await batch.commit(noResult: true);
      expect(results, isEmpty);
    });

    test('commit rolls back when continueOnError is false', () async {
      await db.execute("INSERT INTO b (name, qty) VALUES ('dup', 1)");
      final batch = db.batch()
        ..insert('b', {'name': 'fresh', 'qty': 2})
        ..insert('b', {'name': 'dup', 'qty': 3}); // UNIQUE violation
      await expectLater(batch.commit(), throwsA(isA<Object>()));
      // Rolled back: 'fresh' must not be present.
      final rows = await db.query('b', where: 'name = ?', whereArgs: ['fresh']);
      expect(rows, isEmpty);
    });

    test(
      'commit with continueOnError collects errors and commits rest',
      () async {
        await db.execute("INSERT INTO b (name, qty) VALUES ('dup', 1)");
        final batch = db.batch()
          ..insert('b', {'name': 'ok', 'qty': 2})
          ..insert('b', {'name': 'dup', 'qty': 3}); // fails
        final results = await batch.commit(continueOnError: true);
        expect(results.any((r) => r is Object && r is! int), isTrue);
        final rows = await db.query('b', where: 'name = ?', whereArgs: ['ok']);
        expect(rows, isNotEmpty);
      },
    );
  });

  group('Database adapter — CHECK constraint exception mapping', () {
    late Database db;

    tearDown(() => db.close());

    test('resolves column from values via constraint match', () async {
      db = await Database.open(':memory:');
      await db.execute(
        "CREATE TABLE c (id INTEGER PRIMARY KEY, age INTEGER CHECK (age >= 0))",
      );
      await expectLater(
        db.insert('c', {'age': -1}),
        throwsA(
          isA<PhormCHECKValidatorException>().having(
            (e) => e.column,
            'column',
            'age',
          ),
        ),
      );
    });

    test('strips _length and table prefix when no value matches', () async {
      db = await Database.open(':memory:');
      // Named constraint c_name_length; insert uses different column name so the
      // fallback cleaning path (_length strip + table prefix strip) is taken.
      await db.execute(
        "CREATE TABLE c (id INTEGER PRIMARY KEY, name TEXT, "
        "CONSTRAINT c_name_length CHECK (length(name) >= 3))",
      );
      await expectLater(
        db.rawQuery("INSERT INTO c (id, name) VALUES (1, 'ab')"),
        throwsA(isA<PhormCHECKValidatorException>()),
      );
    });

    test('non-CHECK SqliteException is rethrown', () async {
      db = await Database.open(':memory:');
      await db.execute('CREATE TABLE c (id INTEGER PRIMARY KEY)');
      await expectLater(
        db.rawQuery('SELECT * FROM does_not_exist'),
        throwsA(isA<Object>()),
      );
    });
  });

  group('NativeDatabaseIsolate + BatchBuilder (main-isolate paths)', () {
    late NativeDatabaseIsolate isolate;

    setUp(() async {
      isolate = NativeDatabaseIsolate();
      await isolate.start();
      await isolate.start(); // idempotent second call
      await isolate.open(':memory:');
      await isolate.execute(
        'CREATE TABLE n (id INTEGER PRIMARY KEY, name TEXT, qty INTEGER)',
      );
    });

    tearDown(() async {
      await isolate.stop();
      await isolate.stop(); // idempotent second call
    });

    test('insert/update/delete/query/version wrappers', () async {
      final id = await isolate.insert('n', {'name': 'a', 'qty': 1});
      expect(id, greaterThan(0));

      final updated = await isolate.update(
        'n',
        {'qty': 2},
        where: 'name = ?',
        whereArgs: ['a'],
      );
      expect(updated, 1);

      final rows = await isolate.query('SELECT * FROM n');
      expect(rows.single['qty'], 2);

      await isolate.setVersion(3);
      expect(await isolate.getVersion(), 3);

      final deleted = await isolate.delete(
        'n',
        where: 'name = ?',
        whereArgs: ['a'],
      );
      expect(deleted, 1);
    });

    test('transaction command list', () async {
      await isolate.transaction<Object?>([
        const ExecuteCommand("INSERT INTO n (name, qty) VALUES ('t', 1)", null),
        const ExecuteCommand("UPDATE n SET qty = 5 WHERE name = 't'", null),
      ]);
      final rows = await isolate.query("SELECT qty FROM n WHERE name = 't'");
      expect(rows.single['qty'], 5);
    });

    test('createBatch builds and commits operations', () async {
      final batch = isolate.createBatch()
        ..insert('n', {'name': 'i1', 'qty': 1})
        ..insert('n', {'name': 'i2', 'qty': 2}, replace: true)
        ..update('n', {'qty': 9}, where: 'name = ?', whereArgs: ['i1'])
        ..delete('n', where: 'name = ?', whereArgs: ['i2']);
      final result = await batch.commit();
      expect(result, isNotEmpty);

      final rows = await isolate.query('SELECT * FROM n');
      expect(rows.single['name'], 'i1');
    });

    test('createBatch commit with noResult returns empty', () async {
      final batch = isolate.createBatch()..insert('n', {'name': 'x', 'qty': 1});
      final result = await batch.commit(noResult: true);
      expect(result, isEmpty);
    });

    test('sendBatchCommand returns operation count', () async {
      final count = await isolate.sendBatchCommand([
        const BatchInsert('n', {'name': 's1', 'qty': 1}, false),
        const BatchInsert('n', {'name': 's2', 'qty': 2}, true),
      ]);
      expect(count, 2);
    });

    test('changeStream emits table names on writes', () async {
      final events = <String>[];
      final sub = isolate.changeStream.listen(events.add);
      await isolate.insert('n', {'name': 'evt', 'qty': 1});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(events, contains('n'));
    });
  });

  group('NativeDatabaseIsolate — error & rollback paths', () {
    test('commands before open throw "Database not opened"', () async {
      final iso = NativeDatabaseIsolate();
      await iso.start();
      await expectLater(iso.execute('SELECT 1'), throwsStateError);
      await expectLater(iso.query('SELECT 1'), throwsStateError);
      await expectLater(iso.insert('t', {'a': 1}), throwsStateError);
      await expectLater(
        iso.update('t', {'a': 1}, where: 'a = ?', whereArgs: [1]),
        throwsStateError,
      );
      await expectLater(
        iso.delete('t', where: 'a = ?', whereArgs: [1]),
        throwsStateError,
      );
      await expectLater(iso.getVersion(), throwsStateError);
      await expectLater(iso.setVersion(1), throwsStateError);
      await expectLater(
        iso.sendBatchCommand(const [
          BatchInsert('t', {'a': 1}, false),
        ]),
        throwsStateError,
      );
      await expectLater(
        iso.transaction<Object?>(const [ExecuteCommand('SELECT 1', null)]),
        throwsStateError,
      );
      await iso.stop();
    });

    test('re-open disposes previous database', () async {
      final iso = NativeDatabaseIsolate();
      await iso.start();
      await iso.open(':memory:');
      await iso.execute('CREATE TABLE a (id INTEGER)');
      // Re-open a fresh in-memory db; previous one is disposed.
      await iso.open(':memory:');
      await iso.execute('CREATE TABLE b (id INTEGER)');
      final rows = await iso.query(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names = rows.map((r) => r['name']).toList();
      expect(names, contains('b'));
      expect(names, isNot(contains('a')));
      await iso.stop();
    });

    test('batch rolls back on failure', () async {
      final iso = NativeDatabaseIsolate();
      await iso.start();
      await iso.open(':memory:');
      await iso.execute('CREATE TABLE r (id INTEGER PRIMARY KEY, v TEXT)');
      await expectLater(
        iso.sendBatchCommand(const [
          BatchInsert('r', {'v': 'ok'}, false),
          BatchInsert('nonexistent_table', {'v': 'boom'}, false),
        ]),
        throwsA(isA<Object>()),
      );
      final rows = await iso.query('SELECT * FROM r');
      expect(rows, isEmpty); // rolled back
      await iso.stop();
    });

    test('transaction rolls back on failure', () async {
      final iso = NativeDatabaseIsolate();
      await iso.start();
      await iso.open(':memory:');
      await iso.execute('CREATE TABLE r (id INTEGER PRIMARY KEY, v TEXT)');
      await expectLater(
        iso.transaction<Object?>(const [
          ExecuteCommand("INSERT INTO r (v) VALUES ('ok')", null),
          ExecuteCommand('INSERT INTO missing VALUES (1)', null),
        ]),
        throwsA(isA<Object>()),
      );
      final rows = await iso.query('SELECT * FROM r');
      expect(rows, isEmpty); // rolled back
      await iso.stop();
    });
  });

  group('normalize helpers', () {
    test('normalizeArg handles enum, DateTime, null, passthrough', () {
      expect(normalizeArg(null), isNull);
      expect(normalizeArg(_Color.red), 'red');
      final dt = DateTime.utc(2020, 1, 2, 3, 4, 5);
      expect(normalizeArg(dt), dt.toIso8601String());
      expect(normalizeArg(42), 42);
    });

    test('normalizeArgs / normalizeMap', () {
      expect(normalizeArgs(null), isNull);
      expect(normalizeArgs([_Color.red, 1]), ['red', 1]);
      expect(normalizeMap({'a': _Color.red, 'b': 2}), {'a': 'red', 'b': 2});
    });
  });
}

enum _Color { red }
