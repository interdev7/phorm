import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'models/user.dart';

void main() {
  late DB dbManager;
  late SqflowCore<User> userService;

  setUp(() async {
    dbManager = DB.autoVersion(
      databaseName: ':memory:',
      tables: [usersTable],
      singleInstance: false,
    );
    userService = SqflowCore<User>(dbManager: dbManager, table: usersTable);
  });

  tearDown(() async {
    await dbManager.close();
  });

  test('readAll uses isolate for > 50 rows', () async {
    // Insert 100 users
    final users = List.generate(
        100,
        (i) => User(
              id: 'u$i',
              firstName: 'User$i',
              lastName: 'Last$i',
              email: 'user$i@example.com',
              phone: '123456789$i',
              gender: 'Other',
              city: 'City$i',
              country: 'Country$i',
              isActive: true,
              isVerified: false,
            ));

    await userService.insertBatch(users);

    // Read all users - this should trigger the isolate path
    final result = await userService.readAll(limit: 100);

    expect(result.data.length, 100);
    expect(result.data.first.id, 'u0');
    expect(result.data.last.id, 'u99');
  });
}
