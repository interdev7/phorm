// Cross-ORM benchmark: PHORM vs drift vs raw sqlite3.
//
// Run with:  cd benchmarks && flutter test test/orm_benchmark_test.dart
//
// Every implementation runs the same four scenarios against an in-memory
// SQLite database. Reported numbers are the median of [_runs] measured runs
// after one warmup run. All timings are end-to-end from the caller's
// perspective (including phorm's background-isolate round trip).
//
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart' as drift_native;
import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_benchmarks/drift_db.dart';
import 'package:phorm_benchmarks/phorm_models.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

const int _users = 5000;
const int _treeUsers = 500;
const int _postsPerUser = 10;
const int _runs = 5;

final Map<String, Map<String, double>> _results = {};

Future<double> _measure(Future<void> Function() body) async {
  final sw = Stopwatch()..start();
  await body();
  sw.stop();
  return sw.elapsedMicroseconds / 1000.0;
}

Future<void> _bench(
  String scenario,
  String orm,
  Future<void> Function() setUpRun,
  Future<void> Function() body,
  Future<void> Function() tearDownRun,
) async {
  final samples = <double>[];
  for (var i = 0; i <= _runs; i++) {
    await setUpRun();
    final ms = await _measure(body);
    await tearDownRun();
    if (i > 0) samples.add(ms); // discard warmup
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  (_results[scenario] ??= {})[orm] = median;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------- PHORM
  group('phorm', () {
    late DB db;
    late PhormCore<PUser> users;
    late PhormCore<PPost> posts;

    Future<void> open() async {
      db = DB(
        version: 1,
        databaseName: ':memory:',
        tables: [pUsersTable, pPostsTable],
        singleInstance: false,
        logger: null,
      );
      users = PhormCore<PUser>(dbManager: db, table: pUsersTable);
      posts = PhormCore<PPost>(dbManager: db, table: pPostsTable);
      await db.database; // force init outside the measured section
    }

    Future<void> close() => db.close();

    List<PUser> makeUsers(int n) => List.generate(
      n,
      (i) => PUser(id: 0, name: 'user $i', age: 18 + i % 60, active: i.isEven),
    );

    test('insert 5k', () async {
      await _bench('insert 5k users (single txn)', 'phorm', open, () async {
        await users.insertBatch(makeUsers(_users));
      }, close);
    });

    test('read 5k', () async {
      await _bench(
        'read + map 5k users',
        'phorm',
        () async {
          await open();
          await users.insertBatch(makeUsers(_users));
        },
        () async {
          final all = await users.readAll(limit: null);
          expect(all.data.length, _users);
        },
        close,
      );
    });

    test('filtered read', () async {
      await _bench(
        'filtered read (~1/6 of 5k)',
        'phorm',
        () async {
          await open();
          await users.insertBatch(makeUsers(_users));
        },
        () async {
          final result = await users.query
              .where(const PhormColumn<int>('age').gt(68))
              .noLimit()
              .get();
          expect(result.length, greaterThan(100));
        },
        close,
      );
    });

    test('relation tree', () async {
      await _bench(
        'load 500 users + 10 posts each',
        'phorm',
        () async {
          await open();
          await users.insertBatch(makeUsers(_treeUsers));
          final allPosts = <PPost>[];
          for (var u = 1; u <= _treeUsers; u++) {
            for (var p = 0; p < _postsPerUser; p++) {
              allPosts.add(PPost(id: 0, userId: u, title: 'post $p of $u'));
            }
          }
          await posts.insertBatch(allPosts);
        },
        () async {
          final result = await users.readAll(
            include: [Includable.table('posts')],
            limit: null,
          );
          expect(result.data.length, _treeUsers);
          expect(result.data.first.posts, hasLength(_postsPerUser));
        },
        close,
      );
    });
  });

  // -------------------------------------------------------------- drift
  group('drift', () {
    late DriftDb db;

    Future<void> open() async {
      db = DriftDb(drift_native.NativeDatabase.memory());
      await db.customStatement(
        'CREATE INDEX IF NOT EXISTS d_posts_user_id ON d_posts(user_id)',
      );
    }

    Future<void> close() => db.close();

    List<DUsersCompanion> makeUsers(int n) => List.generate(
      n,
      (i) => DUsersCompanion.insert(
        name: 'user $i',
        age: 18 + i % 60,
        active: i.isEven,
      ),
    );

    Future<void> seedUsers(int n) async {
      await db.batch((b) => b.insertAll(db.dUsers, makeUsers(n)));
    }

    test('insert 5k', () async {
      await _bench('insert 5k users (single txn)', 'drift', open, () async {
        await db.batch((b) => b.insertAll(db.dUsers, makeUsers(_users)));
      }, close);
    });

    test('read 5k', () async {
      await _bench(
        'read + map 5k users',
        'drift',
        () async {
          await open();
          await seedUsers(_users);
        },
        () async {
          final all = await db.select(db.dUsers).get();
          expect(all.length, _users);
        },
        close,
      );
    });

    test('filtered read', () async {
      await _bench(
        'filtered read (~1/6 of 5k)',
        'drift',
        () async {
          await open();
          await seedUsers(_users);
        },
        () async {
          final result = await (db.select(
            db.dUsers,
          )..where((u) => u.age.isBiggerThanValue(68))).get();
          expect(result.length, greaterThan(100));
        },
        close,
      );
    });

    test('relation tree', () async {
      await _bench(
        'load 500 users + 10 posts each',
        'drift',
        () async {
          await open();
          await seedUsers(_treeUsers);
          await db.batch(
            (b) => b.insertAll(db.dPosts, [
              for (var u = 1; u <= _treeUsers; u++)
                for (var p = 0; p < _postsPerUser; p++)
                  DPostsCompanion.insert(userId: u, title: 'post $p of $u'),
            ]),
          );
        },
        () async {
          // Idiomatic drift: join + group rows into a parent->children map.
          final rows = await (db.select(db.dUsers).join([
            drift.leftOuterJoin(
              db.dPosts,
              db.dPosts.userId.equalsExp(db.dUsers.id),
            ),
          ])).get();
          final grouped = <int, (DUser, List<DPost>)>{};
          for (final row in rows) {
            final user = row.readTable(db.dUsers);
            final post = row.readTableOrNull(db.dPosts);
            final entry = grouped.putIfAbsent(user.id, () => (user, []));
            if (post != null) entry.$2.add(post);
          }
          expect(grouped.length, _treeUsers);
          expect(grouped.values.first.$2, hasLength(_postsPerUser));
        },
        close,
      );
    });
  });

  // ---------------------------------------------------- drift (bg isolate)
  group('drift-bg', () {
    late DriftDb db;
    late Directory tmp;

    Future<void> open() async {
      tmp = await Directory.systemTemp.createTemp('phorm_bench_drift_');
      db = DriftDb(
        drift_native.NativeDatabase.createInBackground(
          File('${tmp.path}/bench.db'),
        ),
      );
      await db.customStatement(
        'CREATE INDEX IF NOT EXISTS d_posts_user_id ON d_posts(user_id)',
      );
    }

    Future<void> close() async {
      await db.close();
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    }

    List<DUsersCompanion> makeUsers(int n) => List.generate(
      n,
      (i) => DUsersCompanion.insert(
        name: 'user $i',
        age: 18 + i % 60,
        active: i.isEven,
      ),
    );

    Future<void> seedUsers(int n) async {
      await db.batch((b) => b.insertAll(db.dUsers, makeUsers(n)));
    }

    test('insert 5k', () async {
      await _bench('insert 5k users (single txn)', 'drift-bg', open, () async {
        await db.batch((b) => b.insertAll(db.dUsers, makeUsers(_users)));
      }, close);
    });

    test('read 5k', () async {
      await _bench(
        'read + map 5k users',
        'drift-bg',
        () async {
          await open();
          await seedUsers(_users);
        },
        () async {
          final all = await db.select(db.dUsers).get();
          expect(all.length, _users);
        },
        close,
      );
    });

    test('filtered read', () async {
      await _bench(
        'filtered read (~1/6 of 5k)',
        'drift-bg',
        () async {
          await open();
          await seedUsers(_users);
        },
        () async {
          final result = await (db.select(
            db.dUsers,
          )..where((u) => u.age.isBiggerThanValue(68))).get();
          expect(result.length, greaterThan(100));
        },
        close,
      );
    });

    test('relation tree', () async {
      await _bench(
        'load 500 users + 10 posts each',
        'drift-bg',
        () async {
          await open();
          await seedUsers(_treeUsers);
          await db.batch(
            (b) => b.insertAll(db.dPosts, [
              for (var u = 1; u <= _treeUsers; u++)
                for (var p = 0; p < _postsPerUser; p++)
                  DPostsCompanion.insert(userId: u, title: 'post $p of $u'),
            ]),
          );
        },
        () async {
          final rows = await (db.select(db.dUsers).join([
            drift.leftOuterJoin(
              db.dPosts,
              db.dPosts.userId.equalsExp(db.dUsers.id),
            ),
          ])).get();
          final grouped = <int, (DUser, List<DPost>)>{};
          for (final row in rows) {
            final user = row.readTable(db.dUsers);
            final post = row.readTableOrNull(db.dPosts);
            final entry = grouped.putIfAbsent(user.id, () => (user, []));
            if (post != null) entry.$2.add(post);
          }
          expect(grouped.length, _treeUsers);
        },
        close,
      );
    });
  });

  // -------------------------------------------------------------- raw sqlite3
  group('raw sqlite3', () {
    late raw.Database db;

    Future<void> open() async {
      db = raw.sqlite3.openInMemory();
      db
        ..execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, age INTEGER NOT NULL, active INTEGER NOT NULL)',
        )
        ..execute(
          'CREATE TABLE posts (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'user_id INTEGER NOT NULL, title TEXT NOT NULL)',
        );
    }

    Future<void> close() async => db.dispose();

    void seedUsers(int n) {
      final stmt = db.prepare(
        'INSERT INTO users (name, age, active) VALUES (?, ?, ?)',
      );
      db.execute('BEGIN');
      for (var i = 0; i < n; i++) {
        stmt.execute(['user $i', 18 + i % 60, i.isEven ? 1 : 0]);
      }
      db.execute('COMMIT');
      stmt.dispose();
    }

    test('insert 5k', () async {
      await _bench(
        'insert 5k users (single txn)',
        'raw sqlite3',
        open,
        () async {
          seedUsers(_users);
        },
        close,
      );
    });

    test('read 5k', () async {
      await _bench(
        'read + map 5k users',
        'raw sqlite3',
        () async {
          await open();
          seedUsers(_users);
        },
        () async {
          final rows = db.select('SELECT * FROM users');
          final mapped = rows
              .map(
                (r) => PUser(
                  id: r['id'] as int,
                  name: r['name'] as String,
                  age: r['age'] as int,
                  active: r['active'] == 1,
                ),
              )
              .toList();
          expect(mapped.length, _users);
        },
        close,
      );
    });

    test('filtered read', () async {
      await _bench(
        'filtered read (~1/6 of 5k)',
        'raw sqlite3',
        () async {
          await open();
          seedUsers(_users);
        },
        () async {
          final rows = db.select('SELECT * FROM users WHERE age > ?', [68]);
          expect(rows.length, greaterThan(100));
        },
        close,
      );
    });

    test('relation tree', () async {
      await _bench(
        'load 500 users + 10 posts each',
        'raw sqlite3',
        () async {
          await open();
          seedUsers(_treeUsers);
          final stmt = db.prepare(
            'INSERT INTO posts (user_id, title) VALUES (?, ?)',
          );
          db.execute('BEGIN');
          for (var u = 1; u <= _treeUsers; u++) {
            for (var p = 0; p < _postsPerUser; p++) {
              stmt.execute([u, 'post $p of $u']);
            }
          }
          db.execute('COMMIT');
          stmt.dispose();
        },
        () async {
          final rows = db.select(
            'SELECT u.*, p.id AS p_id, p.title AS p_title '
            'FROM users u LEFT JOIN posts p ON p.user_id = u.id',
          );
          final grouped = <int, List<String>>{};
          for (final row in rows) {
            grouped
                .putIfAbsent(row['id'] as int, () => [])
                .add(row['p_title'] as String? ?? '');
          }
          expect(grouped.length, _treeUsers);
        },
        close,
      );
    });
  });

  tearDownAll(() {
    final orms = ['phorm', 'drift', 'drift-bg', 'raw sqlite3'];
    print('\n=== ORM benchmark results (median of $_runs runs, ms) ===');
    print('| Scenario | ${orms.join(' | ')} |');
    print('|---|---|---|---|---|');
    for (final entry in _results.entries) {
      final cells = orms
          .map((o) => entry.value[o]?.toStringAsFixed(1) ?? '—')
          .join(' | ');
      print('| ${entry.key} | $cells |');
    }
  });
}
