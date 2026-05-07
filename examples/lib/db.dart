import 'package:sqflow_core/sqflow_core.dart';


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
