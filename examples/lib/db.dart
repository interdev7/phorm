import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/post.dart';
import 'models/todo.dart';
import 'models/user.dart';

final appDb = DB.autoVersion(
  databaseName: 'phorm_showcase.db',
  tables: [
    usersTable,
    postsTable,
    categoriesTable,
    tasksTable,
  ],
);
