import 'package:sqflow_lite/sqflow_lite.dart';


import 'models/post.dart';
import 'models/todo.dart';
import 'models/user.dart';

final appDb = DB.autoVersion(
  databaseName: 'sqflow_showcase.db',
  tables: [
    usersTable,
    postsTable,
    categoriesTable,
    tasksTable,
  ],
);
