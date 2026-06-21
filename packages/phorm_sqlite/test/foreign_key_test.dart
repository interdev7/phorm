import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

void main() {
  setUpAll(() {});

  late DB db;
  late Table<User> usersTable;
  late Table<Post> postsTable;

  setUp(() {
    usersTable = Table<User>(
      type: User,
      name: 'users',
      schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT)',
      fromJson: (json) => User.fromJson(json),
      columns: const ['id', 'name'],
    );

    postsTable = Table<Post>(
      type: Post,
      name: 'posts',
      schema: '''
          CREATE TABLE posts (
            id INTEGER PRIMARY KEY, 
            title TEXT, 
            user_id TEXT, 
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )
      ''',
      fromJson: (json) => Post.fromJson(json),
      relationships: const [
        BelongsTo(
          model: 'users',
          foreignKey: 'user_id',
          onDelete: ReferentialAction.cascade,
        ),
      ],
      columns: const ['id', 'title', 'user_id'],
    );

    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [usersTable, postsTable],
      singleInstance: false,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'onDelete: ReferentialAction.cascade should delete related records',
    () async {
      final database = await db.database;

      // 1. Insert User
      await database.insert('users', {'id': 'u1', 'name': 'John'});

      // 2. Insert Posts for User
      await database.insert('posts', {
        'id': 1,
        'title': 'Post 1',
        'user_id': 'u1',
      });
      await database.insert('posts', {
        'id': 2,
        'title': 'Post 2',
        'user_id': 'u1',
      });

      // Verify initial count
      final initialPosts = await database.query('posts');
      expect(initialPosts, hasLength(2));

      // 3. Delete User
      await database.delete('users', where: 'id = ?', whereArgs: ['u1']);

      // 4. Verify Posts are deleted automatically (Cascade)
      final remainingPosts = await database.query('posts');
      expect(
        remainingPosts,
        isEmpty,
        reason: 'Posts should have been deleted by CASCADE',
      );
    },
  );

  test('ReferentialAction constants values', () {
    expect(ReferentialAction.cascade, 'CASCADE');
    expect(ReferentialAction.setNull, 'SET NULL');
    expect(ReferentialAction.setDefault, 'SET DEFAULT');
    expect(ReferentialAction.restrict, 'RESTRICT');
    expect(ReferentialAction.noAction, 'NO ACTION');
  });
}

// Minimal models for testing
class User extends Model {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as String, name: json['name'] as String);

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Post extends Model {
  final int id;
  final String title;
  final String userId;

  Post({required this.id, required this.title, required this.userId});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as int,
    title: json['title'] as String,
    userId: json['user_id'] as String,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'user_id': userId,
  };
}
