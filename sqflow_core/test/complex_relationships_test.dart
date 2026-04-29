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
    final user =
        await userService.readAsync('u1', include: ['posts', 'profiles']);

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
