import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

// ---------------------------------------------------------------------------
// Test models
// ---------------------------------------------------------------------------

class _User extends Model {
  _User({required this.id, this.name, this.age, this.createdAt});
  final int id;
  final String? name;
  final int? age;
  final String? createdAt;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    if (name != null) 'name': name,
    if (age != null) 'age': age,
    if (createdAt != null) 'created_at': createdAt,
  };
}

// Top-level factory so it can be sent to an isolate.
_User _userFromJson(Map<String, dynamic> m) => _User(
  id: m['id'] as int,
  name: m['name'] as String?,
  age: m['age'] as int?,
);

class _Post extends Model {
  _Post(this.id);
  final int id;
  @override
  Map<String, dynamic> toJson() => {'id': id};
}

class _Comment extends Model {
  _Comment(this.id);
  final int id;
  @override
  Map<String, dynamic> toJson() => {'id': id};
}

// ---------------------------------------------------------------------------
// In-memory fakes built on PHORM's own interfaces (no sqflite)
// ---------------------------------------------------------------------------

class _RecordingBatch implements Batch {
  final List<String> ops = [];

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) => ops.add('insert');

  @override
  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) => ops.add('update');

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) =>
      ops.add('delete');

  @override
  void execute(String sql, [List<Object?>? arguments]) => ops.add('execute');
  @override
  void rawInsert(String sql, [List<Object?>? arguments]) =>
      ops.add('rawInsert');
  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) =>
      ops.add('rawUpdate');
  @override
  void rawDelete(String sql, [List<Object?>? arguments]) =>
      ops.add('rawDelete');

  @override
  Future<List<Object?>> commit({bool? noResult, bool? continueOnError}) async =>
      List<Object?>.filled(ops.length, null);
}

class _RecordingExecutor implements DatabaseExecutor {
  List<Map<String, Object?>> rawQueryResult = const [];
  List<Map<String, Object?>> queryResult = const [];
  int insertResult = 1;
  int updateResult = 1;
  int deleteResult = 1;

  // Captured last-call state for assertions.
  String? lastSql;
  List<Object?>? lastArgs;
  Map<String, Object?>? lastInsertValues;
  ConflictAlgorithm? lastConflict;
  Map<String, Object?>? lastUpdateValues;
  String? lastWhere;
  List<Object?>? lastWhereArgs;
  final List<String> calls = [];
  final List<(String, Map<String, Object?>)> inserts = [];
  _RecordingBatch? lastBatch;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    calls.add('execute');
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    calls.add('rawQuery');
    lastSql = sql;
    lastArgs = arguments;
    return rawQueryResult;
  }

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
  }) async {
    calls.add('query');
    lastWhere = where;
    lastWhereArgs = whereArgs;
    return queryResult;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    calls.add('insert');
    inserts.add((table, Map<String, Object?>.from(values)));
    lastInsertValues = values;
    lastConflict = conflictAlgorithm;
    return insertResult;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    calls.add('update');
    lastUpdateValues = values;
    lastWhere = where;
    lastWhereArgs = whereArgs;
    return updateResult;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    calls.add('delete');
    lastWhere = where;
    lastWhereArgs = whereArgs;
    return deleteResult;
  }

  @override
  Batch batch() => lastBatch = _RecordingBatch();
}

class _FakeDb implements PhormDatabase {
  _FakeDb(
    this._tables,
    this.executorImpl, {
    int isolateThreshold = 1000,
    this.loggerImpl,
  }) : _isolateThreshold = isolateThreshold;

  final List<Table> _tables;
  final _RecordingExecutor executorImpl;
  final int _isolateThreshold;
  final PhormLogger? loggerImpl;
  final StreamController<String> changes = StreamController<String>.broadcast();

  @override
  SqlDialect get dialect => const NoEscapeDialect();
  @override
  List<Table> get tables => _tables;
  @override
  PhormLogger? get logger => loggerImpl;
  @override
  int get isolateThreshold => _isolateThreshold;
  @override
  Stream<String> get changeStream => changes.stream;

  @override
  Future<T> logAction<T>(
    String label,
    List<Object?>? arguments,
    Future<T> Function() action,
  ) => action();
  @override
  Future<DatabaseExecutor> get executor async => executorImpl;
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) =>
      action(executorImpl);
  @override
  Future<void> close() async {
    await changes.close();
  }
}

// ---------------------------------------------------------------------------
// Table builders
// ---------------------------------------------------------------------------

Table<_User> _usersTable({
  bool paranoid = false,
  bool timestamps = true,
  List<Relationship> relationships = const [],
}) => Table<_User>(
  schema:
      'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER)',
  name: 'users',
  type: _User,
  fromJson: _userFromJson,
  paranoid: paranoid,
  timestamps: timestamps,
  relationships: relationships,
  columns: const ['id', 'name', 'age'],
);

Table<_Post> _postsTable({
  bool paranoid = false,
  List<Relationship> relationships = const [],
}) => Table<_Post>(
  schema: 'CREATE TABLE posts (id INTEGER, user_id INTEGER)',
  name: 'posts',
  type: _Post,
  fromJson: (m) => _Post(m['id'] as int),
  paranoid: paranoid,
  relationships: relationships,
  columns: const ['id', 'user_id'],
);

Table<_Comment> _commentsTable({bool paranoid = false}) => Table<_Comment>(
  schema: 'CREATE TABLE comments (id INTEGER, post_id INTEGER)',
  name: 'comments',
  type: _Comment,
  fromJson: (m) => _Comment(m['id'] as int),
  paranoid: paranoid,
  columns: const ['id', 'post_id'],
);

void main() {
  late _RecordingExecutor exec;

  PhormCore<_User> makeCore({
    bool paranoid = false,
    bool timestamps = true,
    List<Relationship> relationships = const [],
    List<Table> extraTables = const [],
    int isolateThreshold = 1000,
  }) {
    final users = _usersTable(
      paranoid: paranoid,
      timestamps: timestamps,
      relationships: relationships,
    );
    final db = _FakeDb(
      [users, ...extraTables],
      exec,
      isolateThreshold: isolateThreshold,
    );
    return PhormCore<_User>(dbManager: db, table: users);
  }

  setUp(() => exec = _RecordingExecutor());

  group('insert', () {
    test(
      'strips autoincrement PK when 0 and sets created_at/updated_at',
      () async {
        final core = makeCore();
        final id = await core.insert(_User(id: 0, name: 'Jo'));
        expect(id, 1);
        expect(exec.lastInsertValues!.containsKey('id'), isFalse);
        expect(exec.lastInsertValues!['created_at'], isNotNull);
        expect(exec.lastInsertValues!['updated_at'], isNotNull);
      },
    );

    test('keeps provided created_at and non-zero PK', () async {
      final core = makeCore();
      await core.insert(_User(id: 5, name: 'Jo'));
      // Non-autoincrement value kept.
      expect(exec.lastInsertValues!['id'], 5);
    });

    test('timestamps: false skips created_at/updated_at', () async {
      final core = makeCore(timestamps: false);
      await core.insert(_User(id: 5, name: 'Jo'));
      expect(exec.lastInsertValues!.containsKey('created_at'), isFalse);
      expect(exec.lastInsertValues!.containsKey('updated_at'), isFalse);
    });

    test('honors an explicit executor argument', () async {
      final other = _RecordingExecutor()..insertResult = 42;
      final core = makeCore();
      final id = await core.insert(_User(id: 1), executor: other);
      expect(id, 42);
      expect(exec.calls, isEmpty);
    });
  });

  group('update / upsert', () {
    test('update removes created_at and targets the primary key', () async {
      final core = makeCore();
      final rows = await core.update(_User(id: 7, name: 'X'));
      expect(rows, 1);
      expect(exec.lastUpdateValues!.containsKey('created_at'), isFalse);
      expect(exec.lastUpdateValues!['updated_at'], isNotNull);
      expect(exec.lastWhere, 'id = ?');
      expect(exec.lastWhereArgs, [7]);
    });

    test('upsert inserts with replace conflict algorithm', () async {
      final core = makeCore();
      await core.upsert(_User(id: 1, name: 'X'));
      expect(exec.lastConflict, ConflictAlgorithm.replace);
    });
  });

  group('delete / restore', () {
    test('hard delete on non-paranoid table', () async {
      final core = makeCore();
      final rows = await core.delete(3);
      expect(rows, 1);
      expect(exec.calls, contains('delete'));
      expect(exec.lastWhereArgs, [3]);
    });

    test('soft delete on paranoid table sets deleted_at via update', () async {
      final core = makeCore(paranoid: true);
      await core.delete(3);
      expect(exec.calls, contains('update'));
      expect(exec.lastUpdateValues!.containsKey('deleted_at'), isTrue);
    });

    test('force delete on paranoid table performs a hard delete', () async {
      final core = makeCore(paranoid: true);
      await core.delete(3, force: true);
      expect(exec.calls, contains('delete'));
    });

    test('restore throws when soft delete not enabled', () async {
      final core = makeCore();
      expect(() => core.restore(1), throwsStateError);
    });

    test('restore clears deleted_at on paranoid table', () async {
      final core = makeCore(paranoid: true);
      await core.restore(1);
      expect(exec.lastUpdateValues!.containsKey('deleted_at'), isTrue);
      expect(exec.lastUpdateValues!['deleted_at'], isNull);
    });
  });

  group('batch operations', () {
    test('empty lists short-circuit to 0 without touching the db', () async {
      final core = makeCore(paranoid: true);
      expect(await core.insertBatch([]), 0);
      expect(await core.updateBatch([]), 0);
      expect(await core.upsertBatch([]), 0);
      expect(await core.deleteBatch([]), 0);
      expect(await core.restoreBatch([]), 0);
      expect(exec.calls, isEmpty);
    });

    test('insertBatch returns the committed op count', () async {
      final core = makeCore();
      final n = await core.insertBatch([_User(id: 1), _User(id: 2)]);
      expect(n, 2);
      expect(exec.lastBatch!.ops, ['insert', 'insert']);
    });

    test('updateBatch / upsertBatch build one op per item', () async {
      final core = makeCore();
      expect(await core.updateBatch([_User(id: 1)]), 1);
      expect(await core.upsertBatch([_User(id: 1), _User(id: 2)]), 2);
    });

    test('deleteBatch hard-deletes on non-paranoid tables', () async {
      final core = makeCore();
      await core.deleteBatch([1, 2]);
      expect(exec.lastBatch!.ops, ['delete', 'delete']);
    });

    test('deleteBatch soft-deletes on paranoid tables', () async {
      final core = makeCore(paranoid: true);
      await core.deleteBatch([1, 2]);
      expect(exec.lastBatch!.ops, ['update', 'update']);
    });

    test('deleteBatch with force hard-deletes on paranoid tables', () async {
      final core = makeCore(paranoid: true);
      await core.deleteBatch([1], force: true);
      expect(exec.lastBatch!.ops, ['delete']);
    });

    test('restoreBatch throws on non-paranoid tables', () async {
      final core = makeCore();
      expect(() => core.restoreBatch([1]), throwsStateError);
    });

    test('restoreBatch updates each id on paranoid tables', () async {
      final core = makeCore(paranoid: true);
      expect(await core.restoreBatch([1, 2]), 2);
      expect(exec.lastBatch!.ops, ['update', 'update']);
    });
  });

  group('readOne', () {
    test('returns null when no row matches', () async {
      exec.rawQueryResult = const [];
      final core = makeCore();
      expect(await core.readOne(1), isNull);
    });

    test('parses a row and unflattens nested / json columns', () async {
      exec.rawQueryResult = [
        {'id': 1, 'name': 'Jo', 'posts__id': 9, 'meta': '{"a":1}'},
      ];
      final core = makeCore();
      final user = await core.readOne(1);
      expect(user, isNotNull);
      expect(user!.id, 1);
    });

    test('keeps a malformed JSON-looking string value as-is', () async {
      exec.rawQueryResult = [
        {'id': 1, 'name': '{broken json', 'posts__id': '[not a list'},
      ];
      final core = makeCore();
      final user = await core.readOne(1);
      expect(user, isNotNull);
      expect(user!.id, 1);
    });

    test('paranoid table adds deleted_at IS NULL unless withDeleted', () async {
      exec.rawQueryResult = const [];
      final core = makeCore(paranoid: true);
      await core.readOne(1);
      expect(exec.lastSql, contains('deleted_at'));

      await core.readOne(1, withDeleted: true);
      expect(exec.lastSql, isNot(contains('deleted_at')));
    });
  });

  group('insertWith (nested writes)', () {
    test('HasMany children get the parent foreign key', () async {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [_postsTable()],
      );
      final id = await core.insertWith(_User(id: 1), {
        'posts': [_Post(10), _Post(11)],
      });
      expect(id, 1);
      expect(exec.inserts, hasLength(3));
      expect(exec.inserts[0].$1, 'users');
      expect(exec.inserts[1].$1, 'posts');
      expect(exec.inserts[1].$2['user_id'], 1);
      expect(exec.inserts[2].$2['user_id'], 1);
    });

    test('autoincrement parent falls back to the returned row id', () async {
      exec.insertResult = 42;
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [_postsTable()],
      );
      await core.insertWith(_User(id: 0), {
        'posts': [_Post(10)],
      });
      expect(exec.inserts[1].$2['user_id'], 42);
    });

    test('ManyToMany children are inserted with pivot rows', () async {
      final core = makeCore(
        relationships: const [
          ManyToMany(
            model: 'posts',
            pivotTable: 'user_posts',
            foreignKey: 'user_id',
            relatedKey: 'post_id',
          ),
        ],
        extraTables: [_postsTable()],
      );
      await core.insertWith(_User(id: 1), {
        'posts': [_Post(10)],
      });
      expect(exec.inserts.map((e) => e.$1), ['users', 'posts', 'user_posts']);
      expect(exec.inserts[2].$2, {'user_id': 1, 'post_id': 10});
    });

    test('unknown relationship name throws', () async {
      final core = makeCore();
      await expectLater(
        core.insertWith(_User(id: 1), {
          'ghosts': [_Post(1)],
        }),
        throwsArgumentError,
      );
    });

    test('works inside an existing executor (no new transaction)', () async {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [_postsTable()],
      );
      await core.insertWith(_User(id: 1), {
        'posts': [_Post(10)],
      }, executor: exec);
      expect(exec.inserts, hasLength(2));
    });

    test('matches a relationship declared with a Type model', () async {
      final core = makeCore(
        relationships: const [HasMany(model: _Post, foreignKey: 'user_id')],
        extraTables: [_postsTable()],
      );
      await core.insertWith(_User(id: 1), {
        'posts': [_Post(10)],
      });
      expect(exec.inserts[1].$2['user_id'], 1);
    });

    test('unregistered related table throws', () async {
      final core = makeCore(
        relationships: const [HasMany(model: 'ghosts', foreignKey: 'user_id')],
      );
      await expectLater(
        core.insertWith(_User(id: 1), {
          'ghosts': [_Post(1)],
        }),
        throwsArgumentError,
      );
    });

    test('null parent link value throws', () async {
      final core = makeCore(
        relationships: const [
          HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'name'),
        ],
        extraTables: [_postsTable()],
      );
      await expectLater(
        core.insertWith(_User(id: 1), {
          'posts': [_Post(1)],
        }),
        throwsArgumentError,
      );
    });

    test('ManyToMany autoincrement child uses returned row id', () async {
      exec.insertResult = 77;
      final autoPosts = Table<_Post>(
        schema:
            'CREATE TABLE posts (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER)',
        name: 'posts',
        type: _Post,
        fromJson: (m) => _Post(m['id'] as int),
        columns: const ['id', 'user_id'],
      );
      final core = makeCore(
        relationships: const [
          ManyToMany(
            model: 'posts',
            pivotTable: 'user_posts',
            foreignKey: 'user_id',
            relatedKey: 'post_id',
          ),
        ],
        extraTables: [autoPosts],
      );
      await core.insertWith(_User(id: 1), {
        'posts': [_Post(0)],
      });
      expect(exec.inserts[2].$2, {'user_id': 1, 'post_id': 77});
    });

    test('BelongsTo children are rejected', () async {
      final core = makeCore(
        relationships: const [BelongsTo(model: 'posts', foreignKey: 'post_id')],
        extraTables: [_postsTable()],
      );
      await expectLater(
        core.insertWith(_User(id: 1), {
          'posts': [_Post(1)],
        }),
        throwsArgumentError,
      );
    });
  });

  group('readAll / readAllWithCount', () {
    test('query.rows() returns raw grouped rows with HAVING args', () async {
      exec.rawQueryResult = [
        {'name': 'A', 'cnt': 3},
      ];
      final core = makeCore();
      const name = PhormColumn<String>('name');
      const id = PhormColumn<int>('id');
      final rows =
          await core.query
              .where(id.gt(0))
              .groupBy([name])
              .having(id.gt(5))
              .noLimit()
              .rows();
      expect(rows, [
        {'name': 'A', 'cnt': 3},
      ]);
      expect(exec.lastSql, contains('GROUP BY name HAVING id > ?'));
      expect(exec.lastSql, isNot(contains('LIMIT')));
      // WHERE args come first, HAVING args after.
      expect(exec.lastArgs, [0, 5]);
    });

    test('readAll maps rows into models', () async {
      exec.rawQueryResult = [
        {'id': 1, 'name': 'A'},
        {'id': 2, 'name': 'B'},
      ];
      final core = makeCore();
      final res = await core.readAll(limit: 10);
      expect(res.data.map((u) => u.id), [1, 2]);
    });

    test('readAllWithCount reads total_count from the first row', () async {
      exec.rawQueryResult = [
        {'id': 1, 'total_count': 57},
      ];
      final core = makeCore();
      final res = await core.readAllWithCount();
      expect(res.count, 57);
      expect(res.data.single.id, 1);
    });

    test('onlyDeleted filters deleted_at IS NOT NULL', () async {
      exec.rawQueryResult = const [];
      final core = makeCore(paranoid: true);
      await core.readAll(onlyDeleted: true);
      expect(exec.lastSql, contains('deleted_at'));
    });

    test('large result sets are parsed via an isolate', () async {
      exec.rawQueryResult = List.generate(3, (i) => {'id': i, 'name': 'n$i'});
      final core = makeCore(isolateThreshold: 1);
      final res = await core.readAll(limit: 100);
      expect(res.data.length, 3);
    });
  });

  group('exists', () {
    test('true when a row is returned', () async {
      exec.queryResult = [
        {'id': 1},
      ];
      final core = makeCore();
      expect(await core.exists(1), isTrue);
    });

    test('false when no row and adds paranoid filter', () async {
      exec.queryResult = const [];
      final core = makeCore(paranoid: true);
      expect(await core.exists(1), isFalse);
      expect(exec.lastWhere, contains('deleted_at'));
    });
  });

  group('aggregates', () {
    test('count/sum/avg/min/max read the val column', () async {
      exec.rawQueryResult = [
        {'val': 12},
      ];
      final core = makeCore();
      expect(await core.count(), 12);
      expect(await core.sum('age'), 12);
      expect(await core.avg('age'), 12);
      expect(await core.min('age'), 12);
      expect(await core.max('age'), 12);
    });

    test('returns 0 on empty result', () async {
      exec.rawQueryResult = const [];
      final core = makeCore();
      expect(await core.count(), 0);
    });

    test('count with an explicit column and a where clause', () async {
      exec.rawQueryResult = [
        {'val': 3},
      ];
      final core = makeCore(paranoid: true);
      final n = await core.count(
        column: 'id',
        where: WhereBuilder().gt('age', 18),
      );
      expect(n, 3);
      expect(exec.lastSql, contains('deleted_at'));
    });

    test('aggregate adds a LEFT JOIN for related-table conditions', () async {
      exec.rawQueryResult = [
        {'val': 1},
      ];
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [_postsTable()],
      );
      await core.count(where: WhereBuilder().eq('posts.id', 1));
      expect(exec.lastSql, contains('LEFT JOIN'));
    });
  });

  group('buildJoinQuery / getBuildJoinQuery', () {
    test('empty column selection falls back to table.*', () async {
      final core = makeCore();
      final sql = core.getBuildJoinQuery(
        attributes: Attributes.include(const []),
      );
      expect(sql, contains('users.*'));
    });

    test('includeTotalCount adds a window count and explain plan prefixes', () {
      final core = makeCore();
      final sql = core.getBuildJoinQuery(
        includeTotalCount: true,
        explainQueryPlan: true,
      );
      expect(sql, contains('COUNT(*) OVER()'));
      expect(sql, startsWith('EXPLAIN QUERY PLAN'));
    });

    test('HasMany include produces a json array subquery', () {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [_postsTable(paranoid: true)],
      );
      final sql = core.getBuildJoinQuery(include: [Includable.table('posts')]);
      expect(sql, contains('posts'));
    });

    test('ManyToMany include joins through the pivot table', () {
      final core = makeCore(
        relationships: const [
          ManyToMany(
            model: 'posts',
            pivotTable: 'user_posts',
            foreignKey: 'user_id',
            relatedKey: 'post_id',
          ),
        ],
        extraTables: [_postsTable()],
      );
      final sql = core.getBuildJoinQuery(include: [Includable.table('posts')]);
      expect(sql, contains('user_posts'));
    });

    test('BelongsTo include produces a scalar subquery', () {
      final core = makeCore(
        relationships: const [BelongsTo(model: 'posts', foreignKey: 'post_id')],
        extraTables: [_postsTable()],
      );
      final sql = core.getBuildJoinQuery(include: [Includable.table('posts')]);
      expect(sql, contains('posts'));
    });

    test('where on a related column injects a LEFT JOIN and GROUP BY', () {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [_postsTable()],
      );
      final sql = core.getBuildJoinQuery(
        where: WhereBuilder().eq('posts.id', 1),
      );
      expect(sql, contains('LEFT JOIN'));
      expect(sql, contains('GROUP BY'));
    });

    test('unknown include relationship is skipped', () {
      final core = makeCore();
      final sql = core.getBuildJoinQuery(
        include: [Includable.table('unknown')],
      );
      expect(sql, contains('FROM users'));
    });
  });

  group('transaction', () {
    test('delegates to the manager and exposes the executor', () async {
      final core = makeCore();
      final result = await core.transaction((txn) async {
        await txn.insert('users', {'id': 1});
        return 'ok';
      });
      expect(result, 'ok');
      expect(exec.calls, contains('insert'));
    });
  });

  group('watchers', () {
    test(
      'watchOne emits initial value then re-reads on matching change',
      () async {
        exec.rawQueryResult = [
          {'id': 1, 'name': 'A'},
        ];
        final users = _usersTable();
        final db = _FakeDb([users], exec);
        final core = PhormCore<_User>(dbManager: db, table: users);

        final future = core.watchOne(1).take(2).toList();
        await pumpEventQueue();
        db.changes
          ..add('other') // ignored, no re-read
          ..add('users'); // matching, triggers second emit
        final emitted = await future;
        await db.close();

        expect(emitted.length, 2);
        expect(emitted.first!.id, 1);
      },
    );

    test('watchAll emits the initial page then re-reads on change', () async {
      exec.rawQueryResult = [
        {'id': 1, 'name': 'A'},
      ];
      final users = _usersTable();
      final db = _FakeDb([users], exec);
      final core = PhormCore<_User>(dbManager: db, table: users);

      final future = core.watchAll().take(2).toList();
      await pumpEventQueue();
      db.changes.add('users');
      final emitted = await future;
      await db.close();

      expect(emitted.length, 2);
      expect(emitted.first.single.id, 1);
    });
  });

  group('PhormQuery executor methods', () {
    test('get / first / getWithCount run against the executor', () async {
      exec.rawQueryResult = [
        {'id': 1, 'name': 'A', 'total_count': 1},
      ];
      final core = makeCore();
      final list =
          await core.query.where(const PhormColumn<int>('age').gt(1)).get();
      expect(list.single.id, 1);

      final one = await core.query.first();
      expect(one!.id, 1);

      final withCount = await core.query.getWithCount();
      expect(withCount.count, 1);
    });

    test('aggregate helpers delegate to the service', () async {
      exec.rawQueryResult = [
        {'val': 4},
      ];
      final core = makeCore();
      expect(await core.query.count(), 4);
      expect(await core.query.sum('age'), 4);
      expect(await core.query.avg('age'), 4);
      expect(await core.query.min('age'), 4);
      expect(await core.query.max('age'), 4);
    });
  });

  group('relationship permutations', () {
    test('nested includes build sub-json for paranoid related tables', () {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [
          _postsTable(
            relationships: const [
              HasMany(model: 'comments', foreignKey: 'post_id'),
            ],
          ),
          _commentsTable(paranoid: true),
        ],
      );
      final sql = core.getBuildJoinQuery(
        include: [
          Includable.table(
            'posts',
            attributes: Attributes.include(const ['id']),
            include: [Includable.table('comments')],
          ),
        ],
      );
      expect(sql, contains('comments'));
    });

    test('nested BelongsTo and ManyToMany within an include', () {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [
          _postsTable(
            relationships: const [
              BelongsTo(model: 'comments', foreignKey: 'comment_id'),
              ManyToMany(
                model: 'users',
                pivotTable: 'post_users',
                foreignKey: 'post_id',
                relatedKey: 'user_id',
              ),
            ],
          ),
          _commentsTable(paranoid: true),
        ],
      );
      final sql = core.getBuildJoinQuery(
        include: [
          Includable.table(
            'posts',
            include: [Includable.table('comments'), Includable.table('users')],
          ),
        ],
      );
      expect(sql, contains('post_users'));
    });

    test('BelongsTo include produces a paranoid-filtered scalar subquery', () {
      final core = makeCore(
        relationships: const [BelongsTo(model: 'posts', foreignKey: 'post_id')],
        extraTables: [_postsTable(paranoid: true)],
      );
      final sql = core.getBuildJoinQuery(include: [Includable.table('posts')]);
      expect(sql, contains('IS NULL'));
    });

    test('ManyToMany include is paranoid-filtered', () {
      final core = makeCore(
        relationships: const [
          ManyToMany(
            model: 'posts',
            pivotTable: 'user_posts',
            foreignKey: 'user_id',
            relatedKey: 'post_id',
          ),
        ],
        extraTables: [_postsTable(paranoid: true)],
      );
      final sql = core.getBuildJoinQuery(include: [Includable.table('posts')]);
      expect(sql, contains('IS NULL'));
    });

    test('where on a BelongsTo column injects the reverse LEFT JOIN', () {
      final core = makeCore(
        relationships: const [BelongsTo(model: 'posts', foreignKey: 'post_id')],
        extraTables: [_postsTable()],
      );
      final sql = core.getBuildJoinQuery(
        where: WhereBuilder().eq('posts.id', 1),
      );
      expect(sql, contains('LEFT JOIN posts'));
    });

    test('where on a ManyToMany column injects pivot + related joins', () {
      final core = makeCore(
        relationships: const [
          ManyToMany(
            model: 'posts',
            pivotTable: 'user_posts',
            foreignKey: 'user_id',
            relatedKey: 'post_id',
          ),
        ],
        extraTables: [_postsTable()],
      );
      final sql = core.getBuildJoinQuery(
        where: WhereBuilder().eq('posts.id', 1),
      );
      expect(sql, contains('user_posts'));
    });

    test('Type-based relationships resolve the related table', () {
      final core = makeCore(
        relationships: const [HasMany(model: _Post, foreignKey: 'user_id')],
        extraTables: [_postsTable()],
      );
      final sql = core.getBuildJoinQuery(include: [Includable.model<_Post>()]);
      expect(sql, contains('posts'));
    });

    test('aggregate injects a BelongsTo LEFT JOIN', () async {
      exec.rawQueryResult = [
        {'val': 1},
      ];
      final core = makeCore(
        relationships: const [BelongsTo(model: 'posts', foreignKey: 'post_id')],
        extraTables: [_postsTable()],
      );
      await core.count(where: WhereBuilder().eq('posts.id', 1));
      expect(exec.lastSql, contains('LEFT JOIN posts'));
    });
  });

  group('read edge cases', () {
    test(
      'default readAll on a paranoid table filters soft-deleted rows',
      () async {
        exec.rawQueryResult = const [];
        final core = makeCore(paranoid: true);
        await core.readAll();
        expect(exec.lastSql, contains('deleted_at'));
      },
    );

    test(
      'withDeleted on a paranoid table omits the deleted_at filter',
      () async {
        exec.rawQueryResult = const [];
        final core = makeCore(paranoid: true);
        await core.readAll(withDeleted: true);
        expect(exec.lastSql, isNot(contains('deleted_at')));
      },
    );

    test('parse failure is logged and rethrown', () async {
      exec.rawQueryResult = [
        {'id': 'not-an-int'},
      ];
      final users = Table<_User>(
        schema: 'CREATE TABLE users (id INTEGER)',
        name: 'users',
        type: _User,
        // Throws because id is not an int.
        fromJson: (m) => _User(id: m['id'] as int),
        columns: const ['id'],
      );
      final db = _FakeDb([users], exec, loggerImpl: const PhormConsoleLogger());
      final core = PhormCore<_User>(dbManager: db, table: users);
      await expectLater(core.readAll(), throwsA(isA<TypeError>()));
    });
  });

  group('misc branches', () {
    test('where() entrypoint returns a query bound to the service', () {
      final core = makeCore();
      final q = core.where(const PhormColumn<int>('age').gt(1));
      expect(q, isA<PhormQuery<_User>>());
      expect(q.toSql(), contains('age'));
    });

    test('explicit columns are honored by buildJoinQuery', () {
      final core = makeCore();
      final sql = core.getBuildJoinQuery(columns: const ['id']);
      expect(sql, contains('users.id'));
    });

    test('insert keeps a client-provided created_at', () async {
      final core = makeCore();
      await core.insert(_User(id: 0, name: 'Jo', createdAt: '2020-01-01'));
      expect(exec.lastInsertValues!['created_at'], '2020-01-01');
    });

    test(
      'Type-based relationship resolves in where-join and aggregate',
      () async {
        exec.rawQueryResult = [
          {'val': 1},
        ];
        final core = makeCore(
          relationships: const [HasMany(model: _Post, foreignKey: 'user_id')],
          extraTables: [_postsTable()],
        );
        final sql = core.getBuildJoinQuery(
          where: WhereBuilder().eq('posts.id', 1),
        );
        expect(sql, contains('LEFT JOIN posts'));

        await core.count(where: WhereBuilder().eq('posts.id', 1));
        expect(exec.lastSql, contains('LEFT JOIN posts'));
      },
    );

    test('nested include with a Type relationship and empty attributes', () {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [
          _postsTable(
            relationships: const [
              HasMany(model: _Comment, foreignKey: 'post_id'),
            ],
          ),
          _commentsTable(paranoid: true),
        ],
      );
      final sql = core.getBuildJoinQuery(
        include: [
          Includable.table(
            'posts',
            include: [
              Includable.table(
                'comments',
                attributes: Attributes.include(const []),
              ),
            ],
          ),
        ],
      );
      expect(sql, contains('comments'));
    });

    test('nested ManyToMany include is paranoid-filtered', () {
      final core = makeCore(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
        extraTables: [
          _postsTable(
            relationships: const [
              ManyToMany(
                model: 'comments',
                pivotTable: 'post_comments',
                foreignKey: 'post_id',
                relatedKey: 'comment_id',
              ),
            ],
          ),
          _commentsTable(paranoid: true),
        ],
      );
      final sql = core.getBuildJoinQuery(
        include: [
          Includable.table('posts', include: [Includable.table('comments')]),
        ],
      );
      expect(sql, contains('post_comments'));
    });
  });

  group('watchers with includes and dependencies', () {
    test('watchOne watches included and dependency tables', () async {
      exec.rawQueryResult = [
        {'id': 1, 'name': 'A'},
      ];
      final users = _usersTable(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
      );
      final posts = _postsTable(
        relationships: const [
          HasMany(model: 'comments', foreignKey: 'post_id'),
        ],
      );
      final db = _FakeDb([users, posts, _commentsTable()], exec);
      final core = PhormCore<_User>(dbManager: db, table: users);

      final future =
          core
              .watchOne(
                1,
                include: [
                  Includable.table(
                    'posts',
                    include: [Includable.table('comments')],
                  ),
                ],
                dependencies: const ['audit'],
              )
              .take(2)
              .toList();
      await pumpEventQueue();
      db.changes.add('audit'); // dependency triggers a re-read
      final emitted = await future;
      await db.close();
      expect(emitted.length, 2);
    });

    test('watchAll watches included and dependency tables', () async {
      exec.rawQueryResult = [
        {'id': 1, 'name': 'A'},
      ];
      final users = _usersTable(
        relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
      );
      final db = _FakeDb([users, _postsTable()], exec);
      final core = PhormCore<_User>(dbManager: db, table: users);

      final future =
          core
              .watchAll(
                include: [Includable.table('posts')],
                dependencies: const ['audit'],
              )
              .take(2)
              .toList();
      await pumpEventQueue();
      db.changes.add('posts'); // included table triggers a re-read
      final emitted = await future;
      await db.close();
      expect(emitted.length, 2);
    });
  });
}
