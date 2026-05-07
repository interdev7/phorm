import 'common.dart';

void main() {
  late SqflowCore<User> userService;

  setUpAll(() {
    initSqflite();
  });

  setUp(() async {
    userService = await createTestService();
  });

  tearDown(() async {
    final db = (await userService.database) as Database;
    await db.close();
  });

  group('SqflowCore Transaction:', () {
    test('Transaction rolls back on error', () async {
      final initialCount = (await userService.readAllWithCount()).count;

      try {
        await userService.transaction((SqflowDatabaseExecutor txn) async {
          // Insert a new user using ORM method with executor
          await userService.insertAsync(
            User(
              id: 'txn_test',
              firstName: 'Transaction',
              lastName: 'Test',
              email: 'txn@test.com',
              phone: '+359888222333',
              gender: 'M',
              city: 'City',
              country: 'Country',
              isActive: true,
              isVerified: false,
            ),
            executor: txn,
          );

          // Simulate an error
          throw Exception('Test rollback');
        });
      } catch (_) {
        // Ignore expected error
      }

      // Verify transaction rolled back
      final finalCount = (await userService.readAllWithCount()).count;
      expect(finalCount, initialCount);

      // Verify user was not inserted
      final user = await userService.readAsync('txn_test');
      expect(user, isNull);
    });

    test('Successful transaction with ORM methods', () async {
      final initialCount = (await userService.readAllWithCount()).count;

      await userService.transaction((txn) async {
        // Insert a user using ORM method
        await userService.insertAsync(
          User(
            id: 'txn_success',
            firstName: 'Success',
            lastName: 'Transaction',
            email: 'success.txn@test.com',
            phone: '+359888333444',
            gender: 'F',
            city: 'City',
            country: 'Country',
            isActive: true,
            isVerified: true,
          ),
          executor: txn,
        );

        // Update an existing user using ORM method
        final userToUpdate = await userService.readAsync('u001', executor: txn);
        if (userToUpdate != null) {
          final updatedData = userToUpdate.toJson();
          updatedData['first_name'] = 'UpdatedInTxn';
          await userService.updateAsync(
            User.fromJson(updatedData),
            executor: txn,
          );
        }
      });

      // Verify both changes were applied
      final finalCount = (await userService.readAllWithCount()).count;
      expect(finalCount, initialCount + 1);

      final newUser = await userService.readAsync('txn_success');
      expect(newUser, isNotNull);
      expect(newUser!.email, 'success.txn@test.com');

      final updatedUser = await userService.readAsync('u001');
      expect(updatedUser!.firstName, 'UpdatedInTxn');
    });
  });
}
