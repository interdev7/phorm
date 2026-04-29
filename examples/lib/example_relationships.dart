import 'package:sqflow_core/sqflow_core.dart';
import 'models/models.dart';

void main() async {
  // 1. Initialize tables (normally generated)
  // userTable and postTable would be imported from generated files

  // 2. Initialize DB
  final db = DB.autoVersion(
    databaseName: 'example.db',
    tables: [usersTable, postsTable],
  );

  // 3. Create services
  final userService = SqflowCore<User>(dbManager: db, table: usersTable);
  final postService = SqflowCore<Post>(dbManager: db, table: postsTable);

  // 4. Usage example: Eager load posts for a user
  print('--- Fetching user with posts ---');
  final userWithPosts = await userService.readAsync('user-1', include: [Includable.model<Post>()]);
  
  if (userWithPosts != null) {
    print('User: ${userWithPosts.firstName} ${userWithPosts.lastName}');
    print('Posts count: ${userWithPosts.posts.length}');
    for (final post in userWithPosts.posts) {
      print('  - Post: ${post.title}');
    }
  }

  // 5. Usage example: Eager load user for a post
  print('\n--- Fetching post with user ---');
  final postWithUser = await postService.readAsync(1, include: [Includable.table('users')]);
  
  if (postWithUser != null) {
    print('Post: ${postWithUser.title}');
    print('Author: ${postWithUser.user?.firstName}');
  }

  // 6. Bulk fetching with relationships
  print('\n--- Fetching all users with posts ---');
  final result = await userService.readAll(include: [Includable.model<Post>()]);
  print('Total users: ${result.count}');
  for (final u in result.data) {
    print('User ${u.id} has ${u.posts.length} posts');
  }
}
