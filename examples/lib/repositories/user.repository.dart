import 'package:sqflow_core/sqflow_core.dart';

import '../main.dart';
import '../models/user.dart';

class UserRepository extends SqflowCore<User> {
  UserRepository()
      : super(
          dbManager: database,
          table: usersTableSchema,
        );
}
