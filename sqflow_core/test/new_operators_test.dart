import 'mock_users.dart';
import 'models/user.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    initSqflite();
  });

  group('New Operators (startsWith, endsWith, notBetween)', () {
    late DB db;
    late SqflowCore<User> service;

    setUp(() async {
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
      );
      appDb = db;
      service = SqflowCore<User>(dbManager: db, table: usersTable);
      await service.insertBatchAsync(mockUsers);
    });

    test('startsWith', () async {
      // Find users whose firstName starts with 'Jo'
      final results = await Users.where(Users.firstName.startsWith('Jo')).get();

      for (final user in results) {
        expect(user.firstName.startsWith('Jo'), true);
      }
      expect(results.length, greaterThan(0));
    });

    test('endsWith', () async {
      // Find users whose email ends with '.com'
      final results = await Users.where(Users.email.endsWith('.com')).get();

      for (final user in results) {
        expect(user.email.endsWith('.com'), true);
      }
      expect(results.length, greaterThan(0));
    });

    test('notBetween', () async {
      // Find users whose age is NOT between 20 and 50
      final results = await Users.where(Users.age.notBetween(20, 50)).get();

      for (final user in results) {
        expect(user.age! < 20 || user.age! > 50, true);
      }
      expect(results.length, greaterThan(0));
    });
  });
}
