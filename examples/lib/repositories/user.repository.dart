import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_example/models/user.dart';

import '../main.dart';

class UserRepository extends SqflowCore<User> {
  UserRepository()
      : super(
          dbManager: database,
          table: usersTable,
        );
}
