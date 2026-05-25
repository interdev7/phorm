import 'package:phorm_sqlite/phorm_sqlite.dart';

import '../mock_users.dart';
import '../models/user.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:phorm_sqlite/phorm_sqlite.dart';

export '../mock_users.dart';
export '../models/user.dart';

Table<User> createUsersTable() {
  return usersTable;
}

Future<SqflowCore<User>> createTestService() async {
  final usersTable = createUsersTable();
  // Using a fresh in-memory database for each test service instance
  // Note: 'memory' with no name might share instance? No, ':memory:' is unique per connection if opened separately,
  // but here we want to ensure isolation.
  // In crud_service_test.dart it used ':memory:'.
  final dbManager = DB(
    databaseName: ':memory:',
    version: 1,
    tables: [usersTable],
    singleInstance: false,
  );
  final userService = SqflowCore<User>(dbManager: dbManager, table: usersTable);

  // Seed initial data
  await userService.insertBatch(mockUsers);

  return userService;
}
