import 'common.dart';

void main() {
  late PhormCore<User> userService;

  setUp(() async {
    userService = await createTestService();
  });

  tearDown(() async {
    await userService.dbManager.close();
  });

  group('PhormCore Batch Operations:', () {
    test('Batch insert', () async {
      final newUsers = [
        User(
          id: 'batch001',
          firstName: 'Batch1',
          lastName: 'Test1',
          email: 'batch1@test.com',
          phone: '+359888666777',
          gender: 'M',
          city: 'City1',
          country: 'Country1',
        ),
        User(
          id: 'batch002',
          firstName: 'Batch2',
          lastName: 'Test2',
          email: 'batch2@test.com',
          phone: '+359888777888',
          gender: 'F',
          city: 'City2',
          country: 'Country2',
        ),
      ];

      await userService.insertBatch(newUsers);

      // Verify both users were added
      final user1 = await userService.readOne('batch001');
      final user2 = await userService.readOne('batch002');

      expect(user1, isNotNull);
      expect(user2, isNotNull);
    });

    test('Batch update', () async {
      // Create users first
      final users = [
        User(
          id: 'batch_update1',
          firstName: 'Original1',
          lastName: 'Test',
          email: 'update1@test.com',
          phone: '+359888888999',
          gender: 'M',
          city: 'Old City',
          country: 'Country',
        ),
        User(
          id: 'batch_update2',
          firstName: 'Original2',
          lastName: 'Test',
          email: 'update2@test.com',
          phone: '+359888999000',
          gender: 'F',
          city: 'Old City',
          country: 'Country',
        ),
      ];

      await userService.insertBatch(users);

      // Prepare updated versions
      final updatedUsers = users
          .map((u) => u.copyWith(
                city: 'Updated City',
                isVerified: true,
              ))
          .toList();

      await userService.updateBatch(updatedUsers);

      // Verify updates
      for (final user in updatedUsers) {
        final retrieved = await userService.readOne(user.id);
        expect(retrieved!.city, 'Updated City');
        expect(retrieved.isVerified, true);
      }
    });

    test('Batch delete', () async {
      // Create users for deletion
      final usersToDelete = [
        User(
          id: 'batch_del1',
          firstName: 'Delete1',
          lastName: 'Test',
          email: 'del1@test.com',
          phone: '+359888000111',
          gender: 'M',
          city: 'City',
          country: 'Country',
        ),
        User(
          id: 'batch_del2',
          firstName: 'Delete2',
          lastName: 'Test',
          email: 'del2@test.com',
          phone: '+359888111222',
          gender: 'F',
          city: 'City',
          country: 'Country',
        ),
      ];

      await userService.insertBatch(usersToDelete);

      // Soft delete
      await userService.deleteBatch(['batch_del1', 'batch_del2']);

      // Verify they are deleted
      for (final id in ['batch_del1', 'batch_del2']) {
        final normal = await userService.readOne(id);
        final withDeleted = await userService.readOne(id, withDeleted: true);

        expect(normal, isNull);
        expect(withDeleted, isNotNull);
      }
    });

    test('Batch operations with empty list', () async {
      // Should not throw
      await userService.insertBatch([]);
      await userService.updateBatch([]);
      await userService.deleteBatch([]);
      await userService.restoreBatch([]);
    });
  });
}
