// Tests for updatesSync-based reactivity (docs/14-reactivity.md).
//
// These tests verify that the sqlite3 updatesSync stream correctly drives
// reactive watchers — without relying on the manual _notify() call path.
// Key scenarios covered:
//   1. changeStream emits table name on ORM insert/update/delete
//   2. watchOne() — initial emission and re-emission on change
//   3. watchAll() — initial emission and re-emission on change
//   4. watchOne() with soft-delete: re-emits after delete, returns null
//   5. RAW SQL execute() triggers updatesSync and re-emits watchers (NEW)
//   6. Explicit dependencies parameter
//   7. Auto-detected include-based dependencies
//   8. Transaction buffering: ONE notification after commit, not per-row
//   9. Transaction rollback: NO notification emitted

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/user.dart';

// ---------------------------------------------------------------------------
// Helper: build a fresh in-memory DB + services for each test
// ---------------------------------------------------------------------------

typedef _TestContext = ({
  DB dbManager,
  PhormCore<User> userService,
  PhormCore<Post> postService,
  DatabaseExecutor db,
});

Future<_TestContext> _setup() async {
  final dbManager = DB.autoVersion(
    databaseName: ':memory:',
    tables: [usersTable, postsTable],
    logger: null, // suppress log noise in tests
  );
  final db = await dbManager.executor;
  final userService = PhormCore<User>(dbManager: dbManager, table: usersTable);
  final postService = PhormCore<Post>(dbManager: dbManager, table: postsTable);
  return (
    dbManager: dbManager,
    userService: userService,
    postService: postService,
    db: db,
  );
}

Future<void> _teardown(_TestContext ctx) => ctx.dbManager.close();

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

User _user({String id = 'u1', String firstName = 'Alice'}) => User(
  id: id,
  firstName: firstName,
  lastName: 'Smith',
  email: '$id@example.com',
  phone: '1234567890',
  gender: 'F',
  city: 'Tashkent',
  country: 'Uzbekistan',
);

Post _post({int id = 1, String userId = 'u1', String title = 'Hello'}) =>
    Post(id: id, title: title, userId: userId);

// ---------------------------------------------------------------------------
// 1. Low-level changeStream
// ---------------------------------------------------------------------------

void main() {
  group('1. changeStream (updatesSync)', () {
    late _TestContext ctx;
    setUp(() async => ctx = await _setup());
    tearDown(() => _teardown(ctx));

    test('emits table name after ORM insert', () async {
      final future = ctx.dbManager.changeStream.first;
      await ctx.userService.insert(_user());
      expect(await future, 'users');
    });

    test('emits table name after ORM update', () async {
      await ctx.userService.insert(_user());

      final future = ctx.dbManager.changeStream.first;
      await ctx.userService.update(_user(firstName: 'Bob'));
      expect(await future, 'users');
    });

    test('emits table name after ORM delete (soft)', () async {
      await ctx.userService.insert(_user());

      final future = ctx.dbManager.changeStream.first;
      await ctx.userService.delete('u1');
      expect(await future, 'users');
    });

    test('emits table name after ORM hard delete', () async {
      await ctx.userService.insert(_user());

      final future = ctx.dbManager.changeStream.first;
      await ctx.userService.delete('u1', force: true);
      expect(await future, 'users');
    });

    // -----------------------------------------------------------------------
    // KEY SCENARIO: raw SQL triggers updatesSync — no manual _notify() needed
    // -----------------------------------------------------------------------
    test(
      'emits table name after raw SQL execute (updatesSync advantage)',
      () async {
        await ctx.userService.insert(_user());

        // Execute a raw UPDATE bypassing ORM — manual _notify() would miss this
        final future = ctx.dbManager.changeStream.first;
        await ctx.db.execute(
          "UPDATE users SET first_name = 'RawName' WHERE id = 'u1'",
        );
        expect(await future, 'users');
      },
    );

    test('emits correct table name for posts insert', () async {
      await ctx.userService.insert(_user());

      final future = ctx.dbManager.changeStream.first;
      await ctx.postService.insert(_post());
      expect(await future, 'posts');
    });
  });

  // ---------------------------------------------------------------------------
  // 2. watchOne()
  // ---------------------------------------------------------------------------

  group('2. watchOne()', () {
    late _TestContext ctx;
    setUp(() async => ctx = await _setup());
    tearDown(() => _teardown(ctx));

    test('emits initial value immediately', () async {
      await ctx.userService.insert(_user());
      final first = await ctx.userService.watchOne('u1').first;
      expect(first?.firstName, 'Alice');
    });

    test('emits null when record does not exist', () async {
      final first = await ctx.userService.watchOne('nonexistent').first;
      expect(first, isNull);
    });

    test('re-emits updated value after ORM update', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchOne('u1');
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.update(_user(firstName: 'Bob'));

      expect((await secondEmission)?.firstName, 'Bob');
    });

    test('re-emits null after hard delete', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchOne('u1');
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.delete('u1', force: true);

      expect(await secondEmission, isNull);
    });

    test('re-emits after RAW SQL update (updatesSync)', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchOne('u1');
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      // Raw SQL — no ORM call, no manual _notify()
      await ctx.db.execute(
        "UPDATE users SET first_name = 'RawUpdate' WHERE id = 'u1'",
      );

      final updated = await secondEmission;
      expect(updated?.firstName, 'RawUpdate');
    });

    test('does NOT re-emit when unrelated table changes', () async {
      print('Starting test: unrelated table changes');
      await ctx.userService.insert(_user());
      await ctx.postService.insert(_post());

      bool emitted = false;
      final sub = ctx.userService.watchOne('u1').skip(1).listen((_) {
        print('watchOne emitted unrelated change!');
        emitted = true;
      });

      // Wait for the stream to fully initialize and yield the first element
      await Future.delayed(const Duration(milliseconds: 50));

      print('Inserting unrelated post');
      await ctx.postService.insert(_post(id: 2, title: 'Second'));

      // Give some time for any potential event propagation
      await Future.delayed(const Duration(milliseconds: 100));

      expect(emitted, isFalse);
      print('Cancelling subscription');
      unawaited(sub.cancel());
      print('Finished test successfully');
    });
  });

  // ---------------------------------------------------------------------------
  // 3. watchAll()
  // ---------------------------------------------------------------------------

  group('3. watchAll()', () {
    late _TestContext ctx;
    setUp(() async => ctx = await _setup());
    tearDown(() => _teardown(ctx));

    test('emits empty list initially when no records', () async {
      final first = await ctx.userService.watchAll().first;
      expect(first, isEmpty);
    });

    test('emits existing records on first emission', () async {
      await ctx.userService.insert(_user(id: 'u1'));
      await ctx.userService.insert(_user(id: 'u2', firstName: 'Bob'));

      final first = await ctx.userService.watchAll().first;
      expect(first.length, 2);
    });

    test('re-emits after insert', () async {
      final stream = ctx.userService.watchAll();
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.insert(_user());

      final list = await secondEmission;
      expect(list.length, 1);
      expect(list.first.firstName, 'Alice');
    });

    test('re-emits after update', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchAll();
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.update(_user(firstName: 'Updated'));

      final list = await secondEmission;
      expect(list.first.firstName, 'Updated');
    });

    test('re-emits after hard delete (record disappears)', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchAll();
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.delete('u1', force: true);

      expect(await secondEmission, isEmpty);
    });

    test('re-emits after RAW SQL insert (updatesSync)', () async {
      final stream = ctx.userService.watchAll();
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      // Direct SQL row insertion — proves updatesSync works without _notify()
      await ctx.db.execute(
        "INSERT INTO users (id, first_name, last_name, email, phone, gender, city, country, is_active, is_verified, created_at, updated_at) "
        "VALUES ('u_raw', 'RawUser', 'Last', 'raw@test.com', '0000000000', 'M', 'City', 'Country', 1, 0, '2026-05-20T12:00:00.000', '2026-05-20T12:00:00.000')",
      );

      final list = await secondEmission;
      expect(list.length, 1);
      expect(list.first.firstName, 'RawUser');
    });

    test('respects where filter after re-emission', () async {
      await ctx.userService.insert(_user(id: 'u1', firstName: 'Alice'));

      final stream = ctx.userService.watchAll(
        where: WhereBuilder().eq('city', 'Tashkent'),
      );
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.insert(_user(id: 'u2', firstName: 'Bob'));

      final list = await secondEmission;
      // Both users are in Tashkent
      expect(list.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Soft-delete behavior in watchers
  // ---------------------------------------------------------------------------

  group('4. Soft delete in watchers', () {
    late _TestContext ctx;
    setUp(() async => ctx = await _setup());
    tearDown(() => _teardown(ctx));

    test('watchOne returns null after soft delete (paranoid mode)', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchOne('u1');
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.delete('u1'); // soft delete

      expect(await secondEmission, isNull);
    });

    test(
      'watchOne with withDeleted: true still shows after soft delete',
      () async {
        await ctx.userService.insert(_user());

        final stream = ctx.userService.watchOne('u1', withDeleted: true);
        final secondEmission = stream.skip(1).first;

        await Future.delayed(const Duration(milliseconds: 50));
        await ctx.userService.delete('u1');

        expect((await secondEmission)?.id, 'u1');
      },
    );

    test('watchAll excludes soft-deleted by default', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchAll();
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.userService.delete('u1');

      expect(await secondEmission, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Explicit dependencies parameter
  // ---------------------------------------------------------------------------

  group('5. Explicit dependencies', () {
    late _TestContext ctx;
    setUp(() async => ctx = await _setup());
    tearDown(() => _teardown(ctx));

    test('watchOne re-emits when explicit dependency table changes', () async {
      await ctx.userService.insert(_user());

      // Watch user WITHOUT include, but WITH explicit 'posts' dependency
      final stream = ctx.userService.watchOne('u1', dependencies: ['posts']);
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.postService.insert(_post());

      final user = await secondEmission;
      expect(user?.id, 'u1'); // re-emitted because 'posts' changed
    });

    test('watchAll re-emits when explicit dependency table changes', () async {
      await ctx.userService.insert(_user());

      final stream = ctx.userService.watchAll(dependencies: ['posts']);
      final secondEmission = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 50));
      await ctx.postService.insert(_post());

      final list = await secondEmission;
      expect(list.length, 1);
    });

    test(
      'without dependency, unrelated table change does NOT re-emit',
      () async {
        print('Starting test: without dependency watchAll');
        await ctx.userService.insert(_user());
        await ctx.postService.insert(_post());

        bool emitted = false;
        final sub = ctx.userService
            .watchAll() // no 'posts' dependency
            .skip(1)
            .listen((_) {
              print('watchAll emitted unrelated change!');
              emitted = true;
            });

        await Future.delayed(const Duration(milliseconds: 50));

        print('Inserting unrelated post in watchAll test');
        await ctx.postService.insert(_post(id: 2, title: 'Second post'));

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emitted, isFalse);
        print('Cancelling watchAll subscription');
        unawaited(sub.cancel());
        print('Finished watchAll test successfully');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 6. Auto-detected include-based dependencies
  // ---------------------------------------------------------------------------

  group('6. Auto include-based dependency detection', () {
    late _TestContext ctx;
    setUp(() async => ctx = await _setup());
    tearDown(() => _teardown(ctx));

    test(
      'watchOne with include re-emits when included table changes',
      () async {
        await ctx.userService.insert(_user());

        final stream = ctx.userService.watchOne(
          'u1',
          include: [Includable.table('posts')],
        );
        final secondEmission = stream.skip(1).first;

        await Future.delayed(const Duration(milliseconds: 50));
        await ctx.postService.insert(_post(userId: 'u1'));

        final user = await secondEmission;
        expect(user?.id, 'u1');
      },
    );

    test(
      'watchAll with include re-emits when included table changes',
      () async {
        await ctx.userService.insert(_user());

        final stream = ctx.userService.watchAll(
          include: [Includable.table('posts')],
        );
        final secondEmission = stream.skip(1).first;

        await Future.delayed(const Duration(milliseconds: 50));
        await ctx.postService.insert(_post(userId: 'u1'));

        final list = await secondEmission;
        expect(list.length, 1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 7. Transaction buffering
  // ---------------------------------------------------------------------------

  group('7. Transaction buffering', () {
    late _TestContext ctx;
    setUp(() async => ctx = await _setup());
    tearDown(() => _teardown(ctx));

    test(
      'multiple inserts in one transaction emit only ONE notification',
      () async {
        final emitted = <String>[];
        final sub = ctx.dbManager.changeStream.listen(emitted.add);

        await Future.delayed(const Duration(milliseconds: 50));

        await ctx.dbManager.transaction((txn) async {
          await ctx.userService.insert(_user(id: 'u1'), executor: txn);
          await ctx.userService.insert(
            _user(id: 'u2', firstName: 'Bob'),
            executor: txn,
          );
          await ctx.userService.insert(
            _user(id: 'u3', firstName: 'Charlie'),
            executor: txn,
          );
        });

        // Wait for notifications to settle
        await Future.delayed(const Duration(milliseconds: 150));
        unawaited(sub.cancel());

        // After transaction: only ONE unique table name should be buffered & emitted
        expect(emitted.where((t) => t == 'users').length, 1);
      },
    );

    test(
      'watchAll receives only ONE re-emission for multi-insert transaction',
      () async {
        final stream = ctx.userService.watchAll();

        // Collect all emissions after initial
        final emissions = <List<User>>[];
        final sub = stream.skip(1).listen(emissions.add);

        await Future.delayed(const Duration(milliseconds: 50));

        await ctx.dbManager.transaction((txn) async {
          await ctx.userService.insert(_user(id: 'u1'), executor: txn);
          await ctx.userService.insert(
            _user(id: 'u2', firstName: 'Bob'),
            executor: txn,
          );
          await ctx.userService.insert(
            _user(id: 'u3', firstName: 'Charlie'),
            executor: txn,
          );
        });

        await Future.delayed(const Duration(milliseconds: 200));
        unawaited(sub.cancel());

        // Exactly 1 re-emission containing all 3 users (not 3 separate emissions)
        expect(emissions.length, 1);
        expect(emissions.first.length, 3);
      },
    );

    test('transaction rollback emits NO notification', () async {
      final emitted = <String>[];
      final sub = ctx.dbManager.changeStream.listen(emitted.add);

      await Future.delayed(const Duration(milliseconds: 50));

      try {
        await ctx.dbManager.transaction((txn) async {
          await ctx.userService.insert(_user(), executor: txn);
          throw Exception('Force rollback');
        });
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 200));
      unawaited(sub.cancel());

      expect(emitted, isEmpty);
    });
  });
} // end main
