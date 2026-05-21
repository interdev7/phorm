import 'common.dart';

void main() {
  late SqflowCore<User> userService;

  setUpAll(() {});

  setUp(() async {
    userService = await createTestService();
  });

  tearDown(() async {
    final db = await userService.database;
    await db.close();
  });

  group('SqflowCore Insert Tests:', () {
    test('Insert and read single record', () async {
      final newUser = User(
        id: 'test001',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        phone: '+359888111222',
        gender: 'M',
        city: 'Test City',
        country: 'Test Country',
      );

      final id = await userService.insert(newUser);
      expect(id, greaterThan(0));

      final retrieved = await userService.readOne('test001');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test001');
      expect(retrieved.email, 'test@example.com');
    });
  });
}
