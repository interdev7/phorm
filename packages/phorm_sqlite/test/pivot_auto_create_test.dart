import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:phorm_sqlite/phorm_sqlite.dart';

// Verifies that when @ManyToMany(createPivot: true) is used, the generator's
// schema string carries an extra `CREATE TABLE IF NOT EXISTS <pivot>` statement
// (appended after the model's CREATE TABLE). DB._createTable splits the schema
// on `;` and executes each statement, so the pivot table is created
// automatically — no manual CREATE TABLE / migration required.
void main() {
  late DB db;
  late Table<User> usersTable;
  late Table<Role> rolesTable;

  setUp(() {
    // This mirrors what phorm_schema_generator now emits for a model whose
    // ManyToMany relation opts in with createPivot: true.
    usersTable = Table<User>(
      type: User,
      name: 'users',
      schema: '''
CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT);
CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL,
  role_id TEXT NOT NULL,
  PRIMARY KEY (user_id, role_id)
);
''',
      fromJson: (json) => User.fromJson(json),
      relationships: const [
        ManyToMany(
          model: 'roles',
          pivotTable: 'user_roles',
          foreignKey: 'user_id',
          relatedKey: 'role_id',
          createPivot: true,
        ),
      ],
      columns: const ['id', 'name'],
    );

    rolesTable = Table<Role>(
      type: Role,
      name: 'roles',
      schema: 'CREATE TABLE roles (id TEXT PRIMARY KEY, title TEXT)',
      fromJson: (json) => Role.fromJson(json),
      relationships: const [
        ManyToMany(
          model: 'users',
          pivotTable: 'user_roles',
          foreignKey: 'role_id',
          relatedKey: 'user_id',
        ),
      ],
      columns: const ['id', 'title'],
    );

    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [usersTable, rolesTable],
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('pivot table is created automatically from the schema string', () async {
    final database = await db.database;

    // No manual pivot creation here — it must already exist.
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='user_roles'",
    );
    expect(tables, hasLength(1), reason: 'user_roles pivot should exist');

    // And it must be usable end-to-end.
    await database.insert('users', {'id': 'u1', 'name': 'John'});
    await database.insert('roles', {'id': 'r1', 'title': 'Admin'});
    await database.insert('user_roles', {'user_id': 'u1', 'role_id': 'r1'});

    final userService = PhormCore<User>(dbManager: db, table: usersTable);
    final user = await userService.readOne(
      'u1',
      include: [Includable.model<Role>()],
    );

    expect(user, isNotNull);
    expect(user!.roles, hasLength(1));
    expect(user.roles.first.title, 'Admin');
  });

  test(
    'pivot table is created on upgrade when the model table already exists',
    () async {
      final dir = await Directory.systemTemp.createTemp('phorm_pivot_upgrade');
      final dbPath = p.join(dir.path, 'app.db');

      // v1: users has NO pivot (createPivot was not yet used).
      final usersV1 = Table<User>(
        type: User,
        name: 'users',
        schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT)',
        fromJson: (json) => User.fromJson(json),
        columns: const ['id', 'name'],
      );
      final dbV1 = DB(databaseName: dbPath, version: 1, tables: [usersV1]);
      await dbV1.database;
      await dbV1.close();

      // v2: pivot added to the existing users schema (as the generator emits).
      final usersV2 = Table<User>(
        type: User,
        name: 'users',
        schema: '''
CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT);
CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL,
  role_id TEXT NOT NULL,
  PRIMARY KEY (user_id, role_id)
);
''',
        fromJson: (json) => User.fromJson(json),
        columns: const ['id', 'name'],
      );
      final dbV2 = DB(databaseName: dbPath, version: 2, tables: [usersV2]);
      final database = await dbV2.database;

      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_roles'",
      );
      expect(
        tables,
        hasLength(1),
        reason: 'pivot should be created on upgrade even though users existed',
      );

      await dbV2.close();
      await dir.delete(recursive: true);
    },
  );

  test(
    'pivot with pivotForeignKeys enforces FK + ON DELETE CASCADE',
    () async {
      // Mirrors generator output for createPivot + pivotForeignKeys: true.
      final users = Table<User>(
        type: User,
        name: 'users',
        schema: '''
CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT);
CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL,
  role_id TEXT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);
''',
        fromJson: (json) => User.fromJson(json),
        columns: const ['id', 'name'],
      );
      final roles = Table<Role>(
        type: Role,
        name: 'roles',
        schema: 'CREATE TABLE roles (id TEXT PRIMARY KEY, title TEXT)',
        fromJson: (json) => Role.fromJson(json),
        columns: const ['id', 'title'],
      );

      final fkDb = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [users, roles],
      );
      final database = await fkDb.database;

      await database.insert('users', {'id': 'u1', 'name': 'John'});
      await database.insert('roles', {'id': 'r1', 'title': 'Admin'});
      await database.insert('user_roles', {'user_id': 'u1', 'role_id': 'r1'});

      // Inserting a pivot row with a non-existent user must be rejected.
      await expectLater(
        database.insert('user_roles', {'user_id': 'ghost', 'role_id': 'r1'}),
        throwsA(anything),
      );

      // Deleting the user cascades to the pivot row.
      await database.delete('users', where: 'id = ?', whereArgs: ['u1']);
      final remaining = await database.rawQuery('SELECT * FROM user_roles');
      expect(remaining, isEmpty, reason: 'ON DELETE CASCADE should clear pivot');

      await fkDb.close();
    },
  );
}

class User extends Model {
  final String id;
  final String name;
  final List<Role> roles;

  User({required this.id, required this.name, this.roles = const []});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      roles:
          json['roles'] != null
              ? (json['roles'] as List)
                  .map((r) => Role.fromJson(r as Map<String, dynamic>))
                  .toList()
              : const [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Role extends Model {
  final String id;
  final String title;

  Role({required this.id, required this.title});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'] as String, title: json['title'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}
