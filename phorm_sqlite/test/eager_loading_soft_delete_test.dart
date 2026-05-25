import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'models/user.dart';

void main() {
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

  test('Eager loading relationship: filters out soft-deleted nested objects',
      () async {
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

    // 2. Create an active post
    await database.insert('posts', {
      'id': 10,
      'title': 'Active Post',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    // 3. Create a soft-deleted post
    await database.insert('posts', {
      'id': 20,
      'title': 'Deleted Post',
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now,
      'deleted_at': now, // Mark as soft-deleted
    });

    final userService = SqflowCore<User>(dbManager: db, table: usersTable);

    // 4. Load User with Posts
    final user = await userService.readOne('u1', include: [
      Includable.model<Post>(),
    ]);

    expect(user, isNotNull);
    // Since Post is paranoid, the soft-deleted post (id 20) should NOT be returned by the subquery!
    expect(user!.posts, hasLength(1));
    expect(user.posts[0].id, 10);
    expect(user.posts[0].title, 'Active Post');
  });
}
