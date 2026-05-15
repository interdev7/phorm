import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DB db;
  late Table<User> usersTable;
  late Table<Role> rolesTable;

  setUp(() {
    usersTable = Table<User>(
      type: User,
      name: 'users',
      schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT)',
      fromJson: (json) => User.fromJson(json),
      relationships: const [
        ManyToMany(
          model: 'roles',
          pivotTable: 'user_roles',
          foreignKey: 'user_id',
          relatedKey: 'role_id',
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

  test('Eager load ManyToMany: User with Roles', () async {
    final database = await db.database;

    // Create pivot table (usually created by migrations or manually)
    await database.execute(
        'CREATE TABLE user_roles (user_id TEXT, role_id TEXT, PRIMARY KEY (user_id, role_id))');

    // Seed data
    await database.insert('users', {'id': 'u1', 'name': 'John'});
    await database.insert('users', {'id': 'u2', 'name': 'Jane'});

    await database.insert('roles', {'id': 'r1', 'title': 'Admin'});
    await database.insert('roles', {'id': 'r2', 'title': 'Editor'});
    await database.insert('roles', {'id': 'r3', 'title': 'Viewer'});

    await database.insert('user_roles', {'user_id': 'u1', 'role_id': 'r1'});
    await database.insert('user_roles', {'user_id': 'u1', 'role_id': 'r2'});
    await database.insert('user_roles', {'user_id': 'u2', 'role_id': 'r2'});
    await database.insert('user_roles', {'user_id': 'u2', 'role_id': 'r3'});

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // Test readOne with include
    final user = await userService
        .readOne('u1', include: [Includable.model<Role>()]);

    expect(user, isNotNull);
    expect(user!.name, 'John');
    expect(user.roles, hasLength(2));
    expect(user.roles.any((r) => r.title == 'Admin'), isTrue);
    expect(user.roles.any((r) => r.title == 'Editor'), isTrue);
    expect(user.roles.any((r) => r.title == 'Viewer'), isFalse);

    final jane = await userService
        .readOne('u2', include: [Includable.model<Role>()]);
    expect(jane!.roles, hasLength(2));
    expect(jane.roles.any((r) => r.title == 'Editor'), isTrue);
    expect(jane.roles.any((r) => r.title == 'Viewer'), isTrue);
  });

  test('Filter by ManyToMany: Users with specific Role', () async {
    final database = await db.database;
    await database.execute(
        'CREATE TABLE user_roles (user_id TEXT, role_id TEXT, PRIMARY KEY (user_id, role_id))');

    await database.insert('users', {'id': 'u1', 'name': 'John'});
    await database.insert('users', {'id': 'u2', 'name': 'Jane'});
    await database.insert('roles', {'id': 'r1', 'title': 'Admin'});
    await database.insert('user_roles', {'user_id': 'u1', 'role_id': 'r1'});

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // This should trigger the LEFT JOIN logic in buildJoinQuery
    final users = await userService
        .where(const SqflowColumn<String>('roles.title').eq('Admin'))
        .get();

    expect(users, hasLength(1));
    expect(users[0].name, 'John');
  });
}

// Test Models
class User extends Model {
  final String id;
  final String name;
  final List<Role> roles;

  User({required this.id, required this.name, this.roles = const []});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      roles: json['roles'] != null
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
  final List<User> users;

  Role({required this.id, required this.title, this.users = const []});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      title: json['title'] as String,
      users: json['users'] != null
          ? (json['users'] as List)
              .map((u) => User.fromJson(u as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}
