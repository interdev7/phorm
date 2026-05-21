import 'common.dart';

void main() {
  late SqflowCore<User> userService;

  setUp(() async {
    userService = await createTestService();
  });

  tearDown(() async {
    final db = await userService.database;
    await db.close();
  });

  group('SqflowCore Delete/Restore Tests:', () {
    test('Soft delete and restore', () async {
      final user = User(
        id: 'soft_delete_test',
        firstName: 'Soft',
        lastName: 'Delete',
        email: 'soft.delete@test.com',
        phone: '+359888444555',
        gender: 'F',
        city: 'City',
        country: 'Country',

      );

      await userService.insert(user);

      // Soft delete
      final deleteRows = await userService.delete('soft_delete_test');
      expect(deleteRows, 1);

      // Verify user not present in normal read
      final normalRead = await userService.readOne('soft_delete_test');
      expect(normalRead, isNull);

      // Verify user available with withDeleted
      final withDeletedRead = await userService.readOne(
        'soft_delete_test',
        withDeleted: true,
      );
      expect(withDeletedRead, isNotNull);
      expect(withDeletedRead!.deletedAt, isNotNull);

      // Restore
      final restoreRows = await userService.restore('soft_delete_test');
      expect(restoreRows, 1);

      final restored = await userService.readOne('soft_delete_test');
      expect(restored, isNotNull);
      expect(restored!.deletedAt, isNull);
    });

    test('Force delete (hard delete)', () async {
      final user = User(
        id: 'force_delete_test',
        firstName: 'Force',
        lastName: 'Delete',
        email: 'force.delete@test.com',
        phone: '+359888555666',
        gender: 'M',
        city: 'City',
        country: 'Country',

      );

      await userService.insert(user);

      // Hard delete
      final deleteRows = await userService.delete(
        'force_delete_test',
        force: true,
      );
      expect(deleteRows, 1);

      // Verify user absent even with withDeleted
      final read = await userService.readOne(
        'force_delete_test',
        withDeleted: true,
      );
      expect(read, isNull);
    });

    test('Delete nonexistent record', () async {
      final rows = await userService.delete('non_existent');
      expect(rows, 0);
    });

    test('Restore nonexistent record', () async {
      final rows = await userService.restore('non_existent');
      expect(rows, 0);
    });
  });
}
