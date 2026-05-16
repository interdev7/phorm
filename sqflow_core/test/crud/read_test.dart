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

  group('SqflowCore Read Tests:', () {
    test('Existence check', () async {
      // Existing user (seeded in createTestService)
      final exists = await userService.exists('u001');
      expect(exists, true);

      // Nonexistent user
      final notExists = await userService.exists('nonexistent');
      expect(notExists, false);

      // Deleted user (without withDeleted)
      await userService.delete('u002');
      final deletedExists = await userService.exists('u002');
      expect(deletedExists, false);

      // Deleted user (with withDeleted)
      final deletedExistsWith = await userService.exists(
        'u002',
        withDeleted: true,
      );
      expect(deletedExistsWith, true);
    });

    test('Read nonexistent record', () async {
      final user = await userService.readOne('nonexistent_id');
      expect(user, isNull);
    });
  });
}
