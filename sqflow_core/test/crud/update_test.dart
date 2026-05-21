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

  group('SqflowCore Update Tests:', () {
    test('Update record', () async {
      // Create user first
      final user = User(
        id: 'update_test',
        firstName: 'Original',
        lastName: 'Name',
        email: 'update@test.com',
        phone: '+359888222333',
        gender: 'F',
        city: 'Old City',
        country: 'Old Country',

      );

      await userService.insert(user);

      // Update
      final updatedUser = user.copyWith(
        firstName: 'Updated',
        city: 'New City',
      );

      final rows = await userService.update(updatedUser);
      expect(rows, 1);

      final retrieved = await userService.readOne('update_test');
      expect(retrieved!.firstName, 'Updated');
      expect(retrieved.city, 'New City');
    });

    test('Upsert (insert or replace)', () async {
      final user = User(
        id: 'upsert_test',
        firstName: 'Upsert',
        lastName: 'Test',
        email: 'upsert@test.com',
        phone: '+359888333444',
        gender: 'M',
        city: 'City',
        country: 'Country',

      );

      // First time - insert
      await userService.upsert(user);
      var retrieved = await userService.readOne('upsert_test');
      expect(retrieved!.firstName, 'Upsert');

      // Second time with same id - replace
      final updatedUser = user.copyWith(firstName: 'UpdatedUpsert');
      await userService.upsert(updatedUser);
      retrieved = await userService.readOne('upsert_test');
      expect(retrieved!.firstName, 'UpdatedUpsert');
    });

    test('Update nonexistent record', () async {
      final nonExistentUser = User(
        id: 'non_existent',
        firstName: 'Non',
        lastName: 'Existent',
        email: 'non@existent.com',
        phone: '+359888444555',
        gender: 'M',
        city: 'City',
        country: 'Country',

      );

      final rows = await userService.update(nonExistentUser);
      expect(rows, 0);
    });
  });
}
