import 'package:flutter_test/flutter_test.dart';
import 'package:sqflow_core/sqflow_core.dart';

import '../mock_users.dart';
import '../models/user.dart';

// Re-export needed packages
export 'package:flutter_test/flutter_test.dart';
export 'package:sqflow_core/sqflow_core.dart';
export 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

export '../mock_users.dart';
export '../models/user.dart';
export '../test_utils.dart';

void initSqflite() {
}

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
