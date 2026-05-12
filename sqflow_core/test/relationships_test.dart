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
  late Table<Post> postsTable;

  setUp(() {
    usersTable = Table<User>(
      type: User,
      name: 'users',
      schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT)',
      fromJson: (json) => User.fromJson(json),
      relationships: const [
        HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id'),
      ],
      columns: const ['id', 'name'],
    );

    postsTable = Table<Post>(
      type: Post,
      name: 'posts',
      schema:
          'CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT, user_id TEXT)',
      fromJson: (json) => Post.fromJson(json),
      relationships: const [
        BelongsTo(model: 'users', foreignKey: 'user_id', localKey: 'id'),
      ],
      columns: const ['id', 'title', 'user_id'],
    );

    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [usersTable, postsTable],
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Eager load hasMany: User with Posts', () async {
    final database = await db.database;

    // Seed data
    await database.insert('users', {'id': 'u1', 'name': 'John'});
    await database
        .insert('posts', {'id': 1, 'title': 'Post 1', 'user_id': 'u1'});
    await database
        .insert('posts', {'id': 2, 'title': 'Post 2', 'user_id': 'u1'});
    await database
        .insert('posts', {'id': 3, 'title': 'Post 3', 'user_id': 'other'});

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // Test readAsync with include
    final user =
        await userService.readAsync('u1', include: [Includable.model<Post>()]);

    expect(user, isNotNull);
    expect(user!.name, 'John');
    expect(user.posts, hasLength(2));
    expect(user.posts[0].title, 'Post 1');
    expect(user.posts[1].title, 'Post 2');
  });

  test('Eager load belongsTo: Post with User', () async {
    final database = await db.database;

    // Seed data
    await database.insert('users', {'id': 'u1', 'name': 'John'});
    await database
        .insert('posts', {'id': 1, 'title': 'Post 1', 'user_id': 'u1'});

    final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

    // Test readAsync with include
    final post =
        await postService.readAsync(1, include: [Includable.model<User>()]);

    expect(post, isNotNull);
    expect(post!.title, 'Post 1');
    expect(post.user, isNotNull);
    expect(post.user!.name, 'John');
  });

  test('Eager load in readAll', () async {
    final database = await db.database;

    await database.insert('users', {'id': 'u1', 'name': 'John'});
    await database.insert('users', {'id': 'u2', 'name': 'Jane'});
    await database.insert('posts', {'id': 1, 'title': 'P1', 'user_id': 'u1'});
    await database.insert('posts', {'id': 2, 'title': 'P2', 'user_id': 'u2'});

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    final result =
        await userService.readAll(include: [Includable.model<Post>()]);

    expect(result.data, hasLength(2));
    final john = result.data.firstWhere((u) => u.id == 'u1');
    final jane = result.data.firstWhere((u) => u.id == 'u2');

    expect(john.posts, hasLength(1));
    expect(john.posts[0].title, 'P1');
    expect(jane.posts, hasLength(1));
    expect(jane.posts[0].title, 'P2');
  });
}

// Test Models
class User extends Model {
  final String id;
  final String name;
  final List<Post> posts;

  User({required this.id, required this.name, this.posts = const []});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      posts: json['posts'] != null
          ? (json['posts'] as List)
              .map((p) => Post.fromJson(p as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Post extends Model {
  final int id;
  final String title;
  final String userId;
  final User? user;

  Post(
      {required this.id, required this.title, required this.userId, this.user});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      userId: json['user_id'] as String,
      user: json['users'] != null
          ? User.fromJson(json['users'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'user_id': userId};
}
