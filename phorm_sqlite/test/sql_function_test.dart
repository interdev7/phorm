import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'package:test/test.dart';

import 'models/user.dart';
import 'src/custom_functions.dart';

void main() {
  group('SqlFunction', () {
    group('Constructor', () {
      test('creates function with required parameters', () {
        final fn = SqlFunction(
          name: 'TEST_FUNC',
          argumentCount: 2,
          function: (args) => (args[0] as int) + (args[1] as int),
        );

        expect(fn.name, equals('TEST_FUNC'));
        expect(fn.argumentCount, equals(2));
        expect(fn.deterministic, isTrue);
      });

      test('creates function with deterministic parameter', () {
        final fn = SqlFunction(
          name: 'NON_DETERMINISTIC',
          argumentCount: 0,
          function: (args) => DateTime.now().toString(),
          deterministic: false,
        );

        expect(fn.deterministic, isFalse);
      });

      test('supports variable number of arguments with -1', () {
        final fn = SqlFunction(
          name: 'VARIADIC',
          argumentCount: -1,
          function: (args) => args.length,
        );

        expect(fn.argumentCount, equals(-1));
      });
    });

    group('Database Integration', () {
      late DB db;

      setUp(() async {
        db = DB(
          databaseName: ':memory:',
          version: 1,
          tables: [usersTable],
          customFunctions: [
            SqlFunction.regexp(),
            ...customSqlFunctions,
          ],
        );
      });

      tearDown(() async {
        await db.close();
      });

      test('custom functions are registered and work in database queries',
          () async {
        final database = await db.database;

        final now = DateTime.now().toIso8601String();
        // Insert test data using real columns of usersTable
        await database.insert('users', {
          'id': '1',
          'first_name': 'John',
          'last_name': 'Doe',
          'email': 'john@gmail.com',
          'age': 30,
          'phone': '123456',
          'gender': 'M',
          'city': 'New York',
          'country': 'USA',
          'is_active': 1,
          'is_verified': 1,
          'created_at': now,
          'updated_at': now,
        });
        await database.insert('users', {
          'id': '2',
          'first_name': 'Jane',
          'last_name': 'Smith',
          'email': 'jane@yahoo.com',
          'age': 25,
          'phone': '654321',
          'gender': 'F',
          'city': 'Los Angeles',
          'country': 'USA',
          'is_active': 1,
          'is_verified': 1,
          'created_at': now,
          'updated_at': now,
        });

        // 1. Test REGEXP function
        final gmailUsers = await database.rawQuery(
          r"SELECT * FROM users WHERE email REGEXP '.*@gmail\.com'",
        );
        expect(gmailUsers.length, equals(1));
        expect(gmailUsers.first['first_name'], equals('John'));

        final yahooUsers = await database.rawQuery(
          r"SELECT * FROM users WHERE email REGEXP '.*@yahoo\.com'",
        );
        expect(yahooUsers.length, equals(1));
        expect(yahooUsers.first['first_name'], equals('Jane'));

        // 2. Test DOUBLE function
        final doubleAges = await database.rawQuery(
          "SELECT DOUBLE(age) as double_age FROM users ORDER BY age DESC",
        );
        expect(doubleAges.length, equals(2));
        expect(doubleAges[0]['double_age'], equals(60)); // John: 30 * 2
        expect(doubleAges[1]['double_age'], equals(50)); // Jane: 25 * 2

        // 3. Test TO_SLUG function
        final slugs = await database.rawQuery(
          "SELECT TO_SLUG(first_name || ' ' || last_name) as slug FROM users ORDER BY first_name ASC",
        );
        expect(slugs.length, equals(2));
        expect(slugs[0]['slug'], equals('jane-smith'));
        expect(slugs[1]['slug'], equals('john-doe'));
      });

      test(
          'custom functions work dynamically and type-safely with ORM queries via SqlFunctions helper',
          () async {
        final userService = SqflowCore<User>(dbManager: db, table: usersTable);

        final now = DateTime.now().toIso8601String();
        await userService.insert(User(
          id: '1',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@gmail.com',
          age: 30,
          phone: '123456',
          gender: 'M',
          city: 'New York',
          country: 'USA',
          isActive: true,
          isVerified: true,
        )
          ..createdAt = DateTime.parse(now)
          ..updatedAt = DateTime.parse(now));

        await userService.insert(User(
          id: '2',
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane@yahoo.com',
          age: 20,
          phone: '654321',
          gender: 'F',
          city: 'Los Angeles',
          country: 'USA',
          isActive: true,
          isVerified: true,
        )
          ..createdAt = DateTime.parse(now)
          ..updatedAt = DateTime.parse(now));

        // 1. Query using generated extension doubleValue() on integer column age: Users where DOUBLE(age) > 50 -> (John: 30*2=60 > 50; Jane: 20*2=40 <= 50)
        final results = await userService.readAll(
          where: WhereBuilder().gt(Users.age.doubleValue(), 50),
        );
        expect(results.data.length, equals(1));
        expect(results.data.first.firstName, equals('John'));

        // 2. Query using generated extension toSlug() on string column first_name: Users where TO_SLUG(first_name) = 'jane'
        final results2 = await userService.readAll(
          where: WhereBuilder().eq(Users.firstName.toSlug(), 'jane'),
        );
        expect(results2.data.length, equals(1));
        expect(results2.data.first.firstName, equals('Jane'));

        // 3. Query using generic SqlFunctions.apply helper: Users where DOUBLE(age) = 40 (Jane: 20*2=40)
        final results3 = await userService.readAll(
          where: WhereBuilder()
              .eq(SqlFunctions.apply<int, int>('DOUBLE', Users.age), 40),
        );
        expect(results3.data.length, equals(1));
        expect(results3.data.first.firstName, equals('Jane'));

        // 4. Query using user-defined custom SQL function on the fly via sqlFunction extension: Users where DOUBLE(age) = 60 (John: 30*2=60)
        final results4 = await userService.readAll(
          where: WhereBuilder().eq(Users.age.sqlFunction<int>('DOUBLE'), 60),
        );
        expect(results4.data.length, equals(1));
        expect(results4.data.first.firstName, equals('John'));

        // 5. Query using generated extension doubleValue(): Users where age.doubleValue() = 60
        final results5 = await userService.readAll(
          where: WhereBuilder().eq(Users.age.doubleValue(), 60),
        );
        expect(results5.data.length, equals(1));
        expect(results5.data.first.firstName, equals('John'));

        // 6. Query using generated extension isAdult() on integer column age: Users where IS_ADULT(age) = true
        final results6 = await userService.readAll(
          where: WhereBuilder().eq(Users.age.isAdult(), true),
        );
        expect(results6.data.length, equals(2));
      });
    });
  });
}
