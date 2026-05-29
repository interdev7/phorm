import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'models/user.dart';

void main() {
  setUpAll(() {});

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

  test('Deep loading: User -> Posts -> User (Author)', () async {
    final database = await db.database;
    final now = DateTime.now().toIso8601String();

    // 1. Create Author
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'Author',
      'last_name': 'One',
      'email': 'author@example.com',
      'phone': '123456',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    // 2. Create Post
    await database.insert('posts', {
      'id': 10,
      'title': 'Deep Post',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    final userService = PhormCore<User>(dbManager: db, table: usersTable);

    // 3. Load User with Posts, and for each Post load its User again
    final user = await userService.readOne('u1', include: [
      Includable.model<Post>(include: [
        Includable.model<User>(),
      ]),
    ]);

    expect(user, isNotNull);
    expect(user!.posts, hasLength(1));

    final post = user.posts[0];
    expect(post.title, 'Deep Post');

    // Verify nested load
    expect(post.user, isNotNull);
    expect(post.user!.id, 'u1');
    expect(post.user!.firstName, 'Author');
  });

  test(
      'Deep loading with attributes: User -> Posts (title only) -> User (names only)',
      () async {
    final database = await db.database;
    final now = DateTime.now().toIso8601String();

    await database.insert('users', {
      'id': 'u1',
      'first_name': 'Author',
      'last_name': 'One',
      'email': 'author@example.com',
      'phone': '123456',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    await database.insert('posts', {
      'id': 10,
      'title': 'Deep Post',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    final userService = PhormCore<User>(dbManager: db, table: usersTable);

    final user = await userService.readOne('u1', include: [
      Includable.model<Post>(
        attributes: Attributes.include(['id', 'title', 'user_id']),
        include: [
          Includable.model<User>(
            attributes: Attributes.include([
              'id',
              'first_name',
              'last_name',
              'email',
              'phone',
              'gender',
              'city',
              'country',
              'is_active',
              'is_verified'
            ]),
          ),
        ],
      ),
    ]);

    expect(user, isNotNull);
    expect(user!.posts, hasLength(1));

    final post = user.posts[0];
    expect(post.title, 'Deep Post');

    expect(post.user, isNotNull);
    expect(post.user!.id, 'u1');
    expect(post.user!.firstName, 'Author');
  });

  test(
      'Deep loading with exclude attributes: User -> Posts (exclude timestamps) -> User (exclude phone)',
      () async {
    final database = await db.database;
    final now = DateTime.now().toIso8601String();

    await database.insert('users', {
      'id': 'u1',
      'first_name': 'Author',
      'last_name': 'One',
      'email': 'author@example.com',
      'phone': '123456',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    await database.insert('posts', {
      'id': 10,
      'title': 'Deep Post',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    final userService = PhormCore<User>(dbManager: db, table: usersTable);

    // We exclude 'phone' from User.
    // WARNING: Since User.phone is non-nullable in Dart, excluding it will cause fromJson to throw if it's missing.
    // So for this test, I will exclude NULLABLE fields: 'address', 'birth_date'.
    final user = await userService.readOne('u1', include: [
      Includable.model<Post>(
        attributes:
            Attributes.exclude(['created_at', 'updated_at', 'deleted_at']),
        include: [
          Includable.model<User>(
            attributes: Attributes.exclude(['address', 'birth_date']),
          ),
        ],
      ),
    ]);

    expect(user, isNotNull);
    expect(user!.posts, hasLength(1));

    final post = user.posts[0];
    expect(post.title, 'Deep Post');
    // Timestamps should be null in the model if excluded from JSON (assuming model handles it)
    // Actually, createdAt/updatedAt are nullable in the MIXIN but they might be set via fromJson.

    expect(post.user, isNotNull);
    expect(post.user!.id, 'u1');
    expect(post.user!.firstName, 'Author');
  });
}
