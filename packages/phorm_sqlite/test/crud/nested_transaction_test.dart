import 'common.dart';

User _user(String id) => User(
  id: id,
  firstName: 'Nested',
  lastName: 'Txn',
  email: '$id@test.com',
  phone: '+359888000000',
  gender: 'M',
  city: 'City',
  country: 'Country',
  isActive: true,
  isVerified: false,
);

void main() {
  late PhormCore<User> userService;

  setUp(() async {
    userService = await createTestService();
  });

  tearDown(() async {
    await userService.dbManager.close();
  });

  group('Nested transactions (savepoints):', () {
    test('nested transaction commits together with the outer one', () async {
      await userService.transaction((txn) async {
        await userService.insert(_user('outer_1'), executor: txn);

        await userService.dbManager.transaction((inner) async {
          await userService.insert(_user('inner_1'), executor: inner);
        });
      });

      expect(await userService.readOne('outer_1'), isNotNull);
      expect(await userService.readOne('inner_1'), isNotNull);
    });

    test('failed inner transaction rolls back only its own writes', () async {
      await userService.transaction((txn) async {
        await userService.insert(_user('outer_2'), executor: txn);

        try {
          await userService.dbManager.transaction((inner) async {
            await userService.insert(_user('inner_2'), executor: inner);
            throw Exception('inner failure');
          });
        } catch (_) {
          // Inner failure is handled; the outer transaction continues.
        }

        await userService.insert(_user('outer_2b'), executor: txn);
      });

      expect(await userService.readOne('outer_2'), isNotNull);
      expect(await userService.readOne('outer_2b'), isNotNull);
      expect(await userService.readOne('inner_2'), isNull);
    });

    test('outer rollback reverts committed inner transactions too', () async {
      try {
        await userService.transaction((txn) async {
          await userService.dbManager.transaction((inner) async {
            await userService.insert(_user('inner_3'), executor: inner);
          });
          throw Exception('outer failure');
        });
      } catch (_) {}

      expect(await userService.readOne('inner_3'), isNull);
    });

    test('two levels of nesting work', () async {
      await userService.transaction((txn) async {
        await userService.dbManager.transaction((inner) async {
          await userService.dbManager.transaction((inner2) async {
            await userService.insert(_user('deep_1'), executor: inner2);
          });
        });
      });

      expect(await userService.readOne('deep_1'), isNotNull);
    });
  });
}
