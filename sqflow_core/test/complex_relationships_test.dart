import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';
import 'models/user.dart';

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
    final now = DateTime.now().toIso8601String();
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'John',
      'last_name': 'Doe',
      'email': 'john@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    // Posts
    await database.insert('posts', {
      'id': 1,
      'title': 'First Post',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 2,
      'title': 'Second Post',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    // Profile
    await database.insert('profiles', {
      'id': 100,
      'bio': 'Software Engineer',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // Test readAsync with both relationships
    final user = await userService.readAsync('u1', include: [
      Includable.model<Post>(),
      Includable.model<Profile>(),
    ]);

    expect(user, isNotNull);
    expect(user!.firstName, 'John');

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

    final now = DateTime.now().toIso8601String();
    // Seed User 1
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'John',
      'last_name': 'Doe',
      'email': 'john@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 1,
      'title': 'P1',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('profiles', {
      'id': 10,
      'bio': 'B1',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    // Seed User 2
    await database.insert('users', {
      'id': 'u2',
      'first_name': 'Jane',
      'last_name': 'Doe',
      'email': 'jane@example.com',
      'phone': '123',
      'gender': 'F',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 2,
      'title': 'P2',
      'user_id': 'u2',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 3,
      'title': 'P3',
      'user_id': 'u2',
      'created_at': now,
      'updated_at': now
    });
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

    final now = DateTime.now().toIso8601String();
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'Author',
      'last_name': 'One',
      'email': 'author@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 100,
      'title': 'Hello World',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

    final post =
        await postService.readAsync(100, include: [Includable.model<User>()]);

    expect(post, isNotNull);
    expect(post!.title, 'Hello World');
    expect(post.user, isNotNull);
    expect(post.user!.firstName, 'Author');
    expect(post.userId, 'u1');
  });

  test('BelongsTo batch loading: Many Posts with Users', () async {
    final database = await db.database;

    final now = DateTime.now().toIso8601String();
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'Admin',
      'last_name': 'User',
      'email': 'admin@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('users', {
      'id': 'u2',
      'first_name': 'Editor',
      'last_name': 'User',
      'email': 'editor@example.com',
      'phone': '123',
      'gender': 'F',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    await database.insert('posts', {
      'id': 1,
      'title': 'News 1',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 2,
      'title': 'News 2',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 3,
      'title': 'News 3',
      'user_id': 'u2',
      'created_at': now,
      'updated_at': now
    });

    final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

    final result =
        await postService.readAll(include: [Includable.model<User>()]);

    expect(result.data, hasLength(3));

    for (final post in result.data) {
      expect(post.user, isNotNull);
      if (post.id == 3) {
        expect(post.user!.firstName, 'Editor');
      } else {
        expect(post.user!.firstName, 'Admin');
      }
    }
  });

  test('Complex WhereBuilder with relationships: nested groups and functions',
      () async {
    final database = await db.database;

    final now = DateTime.now().toIso8601String();
    // Seed Data
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'Alice',
      'last_name': 'Admin',
      'email': 'alice@example.com',
      'phone': '123',
      'gender': 'F',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('users', {
      'id': 'u2',
      'first_name': 'Bob',
      'last_name': 'Editor',
      'email': 'bob@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('users', {
      'id': 'u3',
      'first_name': 'Charlie',
      'last_name': 'Guest',
      'email': 'charlie@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    // Posts
    await database.insert('posts', {
      'id': 1,
      'title': 'A1',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 2,
      'title': 'B1',
      'user_id': 'u2',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 3,
      'title': 'C1',
      'user_id': 'u3',
      'created_at': now,
      'updated_at': now
    });

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // Complex filter:
    // (firstName contains 'Alice' OR firstName contains 'Bob')
    // AND (firstName length > 2)
    final where = WhereBuilder().andGroup((ag) {
      ag
        ..orGroup((og) {
          og
            ..like('first_name', '%Alice%')
            ..like('first_name', '%Bob%');
        })
        ..lengthGt('first_name', 2);
    });

    final result = await userService.readAll(
      where: where,
      include: [Includable.model<Post>()],
      sort: SortBuilder().asc('first_name'),
    );

    // Expected: Alice and Bob (Charlie is excluded by orGroup)
    expect(result.data, hasLength(2));
    expect(result.data[0].firstName, contains('Alice'));
    expect(result.data[1].firstName, contains('Bob'));

    // Verify relationships were still loaded for the filtered set
    expect(result.data[0].posts, hasLength(1));
    expect(result.data[0].posts[0].title, 'A1');
    expect(result.data[1].posts, hasLength(1));
    expect(result.data[1].posts[0].title, 'B1');
  });

  test('Complex filtering with BelongsTo: filtering posts by multiple criteria',
      () async {
    final database = await db.database;

    final now = DateTime.now().toIso8601String();
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'Author',
      'last_name': 'A',
      'email': 'a@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('users', {
      'id': 'u2',
      'first_name': 'Author',
      'last_name': 'B',
      'email': 'b@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    await database.insert('posts', {
      'id': 1,
      'title': 'Tech News',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 2,
      'title': 'Tech Review',
      'user_id': 'u2',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 3,
      'title': 'Food Blog',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

    // Filter: title starts with 'Tech' AND user_id is 'u2'
    final where = WhereBuilder().like('title', 'Tech%').eq('user_id', 'u2');

    final result = await postService.readAll(
      where: where,
      include: [Includable.model<User>()],
    );

    expect(result.data, hasLength(1));
    expect(result.data[0].title, 'Tech Review');
    expect(result.data[0].user, isNotNull);
    expect(result.data[0].user!.lastName, 'B');
  });

  test('Filter main table (Users) by related table (Posts) columns', () async {
    final database = await db.database;
    final now = DateTime.now().toIso8601String();

    await database.insert('users', {
      'id': 'ua',
      'first_name': 'Author',
      'last_name': 'A',
      'email': 'ua@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('users', {
      'id': 'ub',
      'first_name': 'Author',
      'last_name': 'B',
      'email': 'ub@example.com',
      'phone': '123',
      'gender': 'M',
      'city': 'Sofia',
      'country': 'Bulgaria',
      'created_at': now,
      'updated_at': now
    });

    await database.insert('posts', {
      'id': 101,
      'title': 'Dart News',
      'user_id': 'ua',
      'created_at': now,
      'updated_at': now
    });
    await database.insert('posts', {
      'id': 102,
      'title': 'Java News',
      'user_id': 'ub',
      'created_at': now,
      'updated_at': now
    });

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // Query: Users who have a post with 'Dart' in title
    // 'posts' is the tableName/relationship name
    final where = WhereBuilder().like('posts.title', 'Dart%');

    final result = await userService.readAll(where: where);

    expect(result.data, hasLength(1));
    expect(result.data[0].lastName, 'A');
  });
}
