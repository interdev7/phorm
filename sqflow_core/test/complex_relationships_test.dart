import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DB db;
  late Table<User> usersTable;
  late Table<Post> postsTable;
  late Table<Profile> profilesTable;

  setUp(() {
    usersTable = Table<User>(
      name: 'users',
      schema: 'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT)',
      fromJson: (json) => User.fromJson(json),
      relationships: const [
        HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id'),
        HasOne(model: 'profiles', foreignKey: 'user_id', localKey: 'id'),
      ],
    );

    postsTable = Table<Post>(
      name: 'posts',
      schema: 'CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT, user_id TEXT)',
      fromJson: (json) => Post.fromJson(json),
      relationships: const [
        BelongsTo(model: 'users', foreignKey: 'user_id', localKey: 'id'),
      ],
    );

    profilesTable = Table<Profile>(
      name: 'profiles',
      schema: 'CREATE TABLE profiles (id INTEGER PRIMARY KEY, bio TEXT, user_id TEXT)',
      fromJson: (json) => Profile.fromJson(json),
      relationships: const [
        BelongsTo(model: 'users', foreignKey: 'user_id', localKey: 'id'),
      ],
    );

    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [usersTable, postsTable, profilesTable],
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Eager load mixed relationships: User with Posts and Profile', () async {
    final database = await db.database;
    
    // Seed data
    await database.insert('users', {'id': 'u1', 'name': 'John Doe'});
    
    // Posts
    await database.insert('posts', {'id': 1, 'title': 'First Post', 'user_id': 'u1'});
    await database.insert('posts', {'id': 2, 'title': 'Second Post', 'user_id': 'u1'});
    
    // Profile
    await database.insert('profiles', {'id': 100, 'bio': 'Software Engineer', 'user_id': 'u1'});

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);
    
    // Test readAsync with both relationships
    final user = await userService.readAsync('u1', include: ['posts', 'profiles']);
    
    expect(user, isNotNull);
    expect(user!.name, 'John Doe');
    
    // Verify collection (HasMany)
    expect(user.posts, hasLength(2));
    expect(user.posts[0].title, 'First Post');
    expect(user.posts[1].title, 'Second Post');
    
    // Verify single object (HasOne)
    expect(user.profile, isNotNull);
    expect(user.profile!.bio, 'Software Engineer');
    expect(user.profile!.userId, 'u1');
  });
}

// Test Models

@Schema(
  tableName: 'users',
  relationships: [
    HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id'),
    HasOne(model: 'profiles', foreignKey: 'user_id', localKey: 'id'),
  ],
)
class User extends Model {
  @ID(type: TEXT())
  @override
  final String id;

  @Column(type: TEXT())
  final String name;

  // These fields are populated via eager loading (include)
  final List<Post> posts;
  final Profile? profile;

  User({
    required this.id,
    required this.name,
    this.posts = const [],
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      posts: json['posts'] != null
          ? (json['posts'] as List)
              .map((p) => Post.fromJson(p as Map<String, dynamic>))
              .toList()
          : const [],
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

@Schema(tableName: 'posts')
class Post extends Model {
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String title;

  @Column(type: TEXT())
  @BelongsTo(model: 'users', foreignKey: 'user_id')
  final String userId;

  Post({required this.id, required this.title, required this.userId});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      userId: json['user_id'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'user_id': userId};
}

@Schema(tableName: 'profiles')
class Profile extends Model {
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String bio;

  @Column(type: TEXT())
  @BelongsTo(model: 'users', foreignKey: 'user_id')
  final String userId;

  Profile({required this.id, required this.bio, required this.userId});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      bio: json['bio'] as String,
      userId: json['user_id'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'bio': bio, 'user_id': userId};
}

