import 'package:sqflow_core/sqflow_core.dart';
import 'package:test/test.dart';
import 'models/user.dart';

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
            SqlFunction.custom(
              name: 'DOUBLE',
              argumentCount: 1,
              function: (args) {
                if (args[0] == null) return null;
                return (args[0] as int) * 2;
              },
            ),
            SqlFunction.custom(
              name: 'TO_SLUG',
              argumentCount: 1,
              function: (args) {
                if (args[0] == null) return null;
                return args[0]
                    .toString()
                    .toLowerCase()
                    // ignore: unnecessary_raw_strings
                    .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
              },
            ),
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
    });
  });
}
