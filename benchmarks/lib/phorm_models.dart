import 'package:phorm_sqlite/phorm_sqlite.dart';

/// Users model (phorm), hand-written to mirror the drift/raw schemas.
class PUser extends Model {
  PUser({
    required this.id,
    required this.name,
    required this.age,
    required this.active,
    this.posts,
  });

  factory PUser.fromJson(Map<String, dynamic> json) => PUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String,
    age: (json['age'] as num).toInt(),
    active: json['active'] == 1 || json['active'] == true,
    posts: (json['posts'] as List?)
        ?.map((p) => PPost.fromJson(p as Map<String, dynamic>))
        .toList(),
  );

  final int id;
  final String name;
  final int age;
  final bool active;
  final List<PPost>? posts;

  @override
  Map<String, dynamic> toJson() => {
    if (id != 0) 'id': id,
    'name': name,
    'age': age,
    'active': active,
  };
}

/// Posts model (phorm).
class PPost extends Model {
  PPost({required this.id, required this.userId, required this.title});

  factory PPost.fromJson(Map<String, dynamic> json) => PPost(
    id: (json['id'] as num?)?.toInt() ?? 0,
    userId: (json['user_id'] as num).toInt(),
    title: json['title'] as String,
  );

  final int id;
  final int userId;
  final String title;

  @override
  Map<String, dynamic> toJson() => {
    if (id != 0) 'id': id,
    'user_id': userId,
    'title': title,
  };
}

/// phorm users table with a HasMany(posts) relationship.
final pUsersTable = Table<PUser>(
  name: 'users',
  schema: '''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  age INTEGER NOT NULL,
  active INTEGER NOT NULL
);
''',
  fromJson: PUser.fromJson,
  type: PUser,
  columns: const ['id', 'name', 'age', 'active'],
  timestamps: false,
  autoIncrement: true,
  relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
);

/// phorm posts table.
final pPostsTable = Table<PPost>(
  name: 'posts',
  schema: '''
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL
);
''',
  fromJson: PPost.fromJson,
  type: PPost,
  columns: const ['id', 'user_id', 'title'],
  timestamps: false,
  autoIncrement: true,
);
