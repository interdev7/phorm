import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

part 'complex_relationships_test.sql.g.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DB db;

  setUp(() {
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
    await database
        .insert('posts', {'id': 1, 'title': 'First Post', 'user_id': 'u1'});
    await database
        .insert('posts', {'id': 2, 'title': 'Second Post', 'user_id': 'u1'});

    // Profile
    await database.insert(
        'profiles', {'id': 100, 'bio': 'Software Engineer', 'user_id': 'u1'});

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // Test readAsync with both relationships
    final user = await userService.readAsync('u1', include: [
      Includable.model<Post>(),
      Includable.model<Profile>(),
    ]);

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

  test('Batch load with readAll: Multiple Users with Posts and Profile',
      () async {
    final database = await db.database;

    // Seed User 1
    await database.insert('users', {'id': 'u1', 'name': 'John'});
    await database.insert('posts', {'id': 1, 'title': 'P1', 'user_id': 'u1'});
    await database.insert('profiles', {'id': 10, 'bio': 'B1', 'user_id': 'u1'});

    // Seed User 2
    await database.insert('users', {'id': 'u2', 'name': 'Jane'});
    await database.insert('posts', {'id': 2, 'title': 'P2', 'user_id': 'u2'});
    await database.insert('posts', {'id': 3, 'title': 'P3', 'user_id': 'u2'});
    // User 2 has no profile (test null handling)

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    final result = await userService.readAll(include: [
      Includable.model<Post>(),
      Includable.model<Profile>(),
    ]);

    expect(result.data, hasLength(2));

    final john = result.data.firstWhere((u) => u.id == 'u1');
    final jane = result.data.firstWhere((u) => u.id == 'u2');

    // John
    expect(john.posts, hasLength(1));
    expect(john.posts[0].title, 'P1');
    expect(john.profile, isNotNull);
    expect(john.profile!.bio, 'B1');

    // Jane
    expect(jane.posts, hasLength(2));
    expect(jane.posts.map((p) => p.title), containsAll(['P2', 'P3']));
    expect(jane.profile, isNull);
  });

  test('BelongsTo eager loading: Post with User', () async {
    final database = await db.database;

    await database.insert('users', {'id': 'u1', 'name': 'Author One'});
    await database.insert('posts', {'id': 100, 'title': 'Hello World', 'user_id': 'u1'});

    final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

    final post = await postService.readAsync(100, include: [Includable.model<User>()]);

    expect(post, isNotNull);
    expect(post!.title, 'Hello World');
    expect(post.user, isNotNull);
    expect(post.user!.name, 'Author One');
    expect(post.userId, 'u1');
  });

  test('BelongsTo batch loading: Many Posts with Users', () async {
    final database = await db.database;

    await database.insert('users', {'id': 'u1', 'name': 'Admin'});
    await database.insert('users', {'id': 'u2', 'name': 'Editor'});

    await database.insert('posts', {'id': 1, 'title': 'News 1', 'user_id': 'u1'});
    await database.insert('posts', {'id': 2, 'title': 'News 2', 'user_id': 'u1'});
    await database.insert('posts', {'id': 3, 'title': 'News 3', 'user_id': 'u2'});

    final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

    final result = await postService.readAll(include: [Includable.model<User>()]);

    expect(result.data, hasLength(3));

    for (final post in result.data) {
      expect(post.user, isNotNull);
      if (post.id == 3) {
        expect(post.user!.name, 'Editor');
      } else {
        expect(post.user!.name, 'Admin');
      }
    }
  });

  test('Complex WhereBuilder with relationships: nested groups and functions', () async {
    final database = await db.database;

    // Seed Data
    await database.insert('users', {'id': 'u1', 'name': 'Alice Admin'}); // Age check will be manual column in a real app, here we use 'name' length or other tricks since User model in this test is simple
    await database.insert('users', {'id': 'u2', 'name': 'Bob Editor'});
    await database.insert('users', {'id': 'u3', 'name': 'Charlie Guest'});

    // Posts
    await database.insert('posts', {'id': 1, 'title': 'A1', 'user_id': 'u1'});
    await database.insert('posts', {'id': 2, 'title': 'B1', 'user_id': 'u2'});
    await database.insert('posts', {'id': 3, 'title': 'C1', 'user_id': 'u3'});

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // Complex filter: 
    // (Name contains 'Alice' OR Name contains 'Bob') 
    // AND (Name length > 5)
    final where = WhereBuilder().andGroup((ag) {
      ag.orGroup((og) {
        og.like('name', '%Alice%').like('name', '%Bob%');
      });
      ag.lengthGt('name', 5);
    });

    final result = await userService.readAll(
      where: where,
      include: [Includable.model<Post>()],
      sort: SortBuilder().asc('name'),
    );

    // Expected: Alice and Bob (Charlie is excluded by orGroup)
    expect(result.data, hasLength(2));
    expect(result.data[0].name, contains('Alice'));
    expect(result.data[1].name, contains('Bob'));

    // Verify relationships were still loaded for the filtered set
    expect(result.data[0].posts, hasLength(1));
    expect(result.data[0].posts[0].title, 'A1');
    expect(result.data[1].posts, hasLength(1));
    expect(result.data[1].posts[0].title, 'B1');
  });

  test('Complex filtering with BelongsTo: filtering posts by multiple criteria', () async {
    final database = await db.database;

    await database.insert('users', {'id': 'u1', 'name': 'Author A'});
    await database.insert('users', {'id': 'u2', 'name': 'Author B'});

    await database.insert('posts', {'id': 1, 'title': 'Tech News', 'user_id': 'u1'});
    await database.insert('posts', {'id': 2, 'title': 'Tech Review', 'user_id': 'u2'});
    await database.insert('posts', {'id': 3, 'title': 'Food Blog', 'user_id': 'u1'});

    final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

    // Filter: title starts with 'Tech' AND user_id is 'u2'
    final where = WhereBuilder()
        .like('title', 'Tech%')
        .eq('user_id', 'u2');

    final result = await postService.readAll(
      where: where,
      include: [Includable.model<User>()],
    );

    expect(result.data, hasLength(1));
    expect(result.data[0].title, 'Tech Review');
    expect(result.data[0].user, isNotNull);
    expect(result.data[0].user!.name, 'Author B');
  });
}

// Test Models

@Schema(
  tableName: 'users',
  relationships: [
    HasMany(model: Post, foreignKey: 'user_id', localKey: 'id'),
    HasOne(model: Profile, foreignKey: 'user_id', localKey: 'id'),
  ],
)
class User extends Model with _$UserMixin {
  @ID(type: TEXT())
  @override
  final String id;

  @Column(type: TEXT())
  final String name;

  User({
    required this.id,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserToJson();
}

@Schema(
  tableName: 'posts',
  relationships: [
    BelongsTo(model: User, foreignKey: 'user_id', localKey: 'id')
  ],
)
class Post extends Model with _$PostMixin {
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String title;

  Post({required this.id, required this.title});

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PostToJson();
}

@Schema(tableName: 'profiles', relationships: [
  BelongsTo(model: User, foreignKey: 'user_id', localKey: 'id')
])
class Profile extends Model with _$ProfileMixin {
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String bio;

  Profile({required this.id, required this.bio});

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProfileToJson();
}
