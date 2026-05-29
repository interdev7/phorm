import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'models/user.dart';

void main() {
  late Database db;
  late DB dbManager;
  late PhormCore<User> userService;
  late PhormCore<Post> postService;

  setUpAll(() {});

  setUp(() async {
    dbManager = DB.autoVersion(
      databaseName: ':memory:',
      tables: [usersTable, postsTable],
    );
    db = await dbManager.database;
    // Clear tables
    await db.delete('users');
    await db.delete('posts');

    userService = PhormCore<User>(dbManager: dbManager, table: usersTable);
    postService = PhormCore<Post>(dbManager: dbManager, table: postsTable);
  });

  tearDown(() async {
    await dbManager.close();
  });

  group('Reactivity Tests (Streams)', () {
    test('watchOne() emits initial value and updates on change', () async {
      final user = User(
        id: 'u1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '123456',
        gender: 'M',
        city: 'NY',
        country: 'USA',
      );

      await userService.insert(user);

      // Initial load
      expect((await userService.watchOne('u1').first)?.firstName, 'John');

      // Now we start listening for the next emission
      final stream = userService.watchOne('u1');
      final futureValue = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 100));

      // Update the user
      await userService.update(user.copyWith(firstName: 'Johnny'));

      final secondEmission = await futureValue;
      expect(secondEmission?.firstName, 'Johnny');
    });

    test('watchAll() emits new list when an item is inserted', () async {
      // Initial list should be empty
      expect(await userService.watchAll().first, isEmpty);

      final stream = userService.watchAll();
      final futureValue = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 100));

      await userService.insert(User(
        id: 'u1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '123456',
        gender: 'M',
        city: 'NY',
        country: 'USA',
      ));

      final secondEmission = await futureValue;
      expect(secondEmission.length, 1);
      expect(secondEmission.first.firstName, 'John');
    });

    test('watchOne() re-emits when a dependency changes', () async {
      final user = User(
        id: 'u1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '123456',
        gender: 'M',
        city: 'NY',
        country: 'USA',
      );
      await userService.insert(user);

      // Verify initial
      expect(
          (await userService.watchOne('u1', dependencies: ['posts']).first)?.id,
          'u1');

      // Watch user and specify 'posts' as a dependency
      final stream = userService.watchOne('u1', dependencies: ['posts']);
      final futureValue = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 100));

      // Insert a post for the user. Even if we don't 'include' posts in the watch,
      // the stream should re-emit because we marked 'posts' as a dependency.
      await postService.insert(Post(
        id: 1,
        title: 'New Post',
        userId: 'u1',
      ));

      final emissionAfterPost = await futureValue;
      expect(emissionAfterPost?.id, 'u1');
      // In a real app, this re-emission is useful if you are using 'include'
      // and want to see the new post in the user object.
    });

    test('watchAll() automatically detects dependencies from includes',
        () async {
      final user = User(
        id: 'u1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '123456',
        gender: 'M',
        city: 'NY',
        country: 'USA',
      );
      await userService.insert(user);

      // Watch all users with posts included
      expect(
          (await userService
                  .watchAll(include: [Includable.table('posts')]).first)
              .first
              .id,
          'u1');

      final stream = userService.watchAll(
        include: [Includable.table('posts')],
      );

      final futureValue = stream.skip(1).first;

      await Future.delayed(const Duration(milliseconds: 100));

      // Add a post. watchAll should detect 'posts' is in 'include' and re-emit.
      await postService.insert(Post(
        id: 1,
        title: 'Post 1',
        userId: 'u1',
      ));

      final updated = await futureValue;
      expect(updated.first.id, 'u1');
      // Note: In our current implementation, we'd need to check if posts were actually loaded.
      // But the main point is the trigger worked.
    });
  });
}
