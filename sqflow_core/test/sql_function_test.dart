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

    group('REGEXP function', () {
      late SqlFunction regexpFn;

      setUp(() {
        regexpFn = SqlFunction.regexp();
      });

      test('has correct name and argument count', () {
        expect(regexpFn.name, equals('REGEXP'));
        expect(regexpFn.argumentCount, equals(2));
      });

      test('is deterministic', () {
        expect(regexpFn.deterministic, isTrue);
      });

      test('matches simple patterns', () {
        final result = regexpFn.function(['hello', 'hello']);
        expect(result, equals(1));
      });

      test('matches regex patterns', () {
        final result = regexpFn.function([r'.*@gmail\.com', 'user@gmail.com']);
        expect(result, equals(1));
      });

      test('returns 0 for non-matching patterns', () {
        final result = regexpFn.function([r'.*@gmail\.com', 'user@yahoo.com']);
        expect(result, equals(0));
      });

      test('handles null arguments gracefully', () {
        final result1 = regexpFn.function([null, 'text']);
        expect(result1, equals(0));

        final result2 = regexpFn.function(['pattern', null]);
        expect(result2, equals(0));
      });

      test('handles invalid regex patterns', () {
        final result = regexpFn.function(['[invalid(regex', 'text']);
        expect(result, equals(0));
      });

      test('matches email pattern', () {
        const emailPattern =
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
        final result1 = regexpFn.function([emailPattern, 'user@example.com']);
        expect(result1, equals(1));

        final result2 = regexpFn.function([emailPattern, 'invalid-email']);
        expect(result2, equals(0));
      });

      test('matches case-sensitive patterns by default', () {
        final result = regexpFn.function(['hello', 'HELLO']);
        expect(result, equals(0));
      });

      test('handles complex patterns with special characters', () {
        const pattern = r'^\d{3}-\d{3}-\d{4}$';
        final result = regexpFn.function([pattern, '123-456-7890']);
        expect(result, equals(1));
      });
    });

    group('Custom function factory', () {
      test('creates custom function with required parameters', () {
        final fn = SqlFunction.custom(
          name: 'DOUBLE',
          argumentCount: 1,
          function: (args) => (args[0] as int) * 2,
        );

        expect(fn.name, equals('DOUBLE'));
        expect(fn.argumentCount, equals(1));
        expect(fn.deterministic, isTrue);
      });

      test('creates non-deterministic custom function', () {
        final fn = SqlFunction.custom(
          name: 'RANDOM',
          argumentCount: 0,
          function: (args) => 42,
          deterministic: false,
        );

        expect(fn.deterministic, isFalse);
      });

      test('works with string manipulation', () {
        final reverseFn = SqlFunction.custom(
          name: 'REVERSE',
          argumentCount: 1,
          function: (args) => (args[0] as String).split('').reversed.join(),
        );

        final result = reverseFn.function(['hello']);
        expect(result, equals('olleh'));
      });

      test('works with arithmetic operations', () {
        final addFn = SqlFunction.custom(
          name: 'ADD',
          argumentCount: 2,
          function: (args) => (args[0] as int) + (args[1] as int),
        );

        final result = addFn.function([10, 5]);
        expect(result, equals(15));
      });

      test('works with null handling', () {
        final nullSafeFn = SqlFunction.custom(
          name: 'NULL_SAFE',
          argumentCount: 1,
          function: (args) => args[0] ?? 'NULL',
        );

        final result1 = nullSafeFn.function([null]);
        expect(result1, equals('NULL'));

        final result2 = nullSafeFn.function(['value']);
        expect(result2, equals('value'));
      });

      test('supports variable argument count', () {
        final concatFn = SqlFunction.custom(
          name: 'CONCAT_ALL',
          argumentCount: -1,
          function: (args) => args.whereType<String>().join(),
        );

        expect(concatFn.argumentCount, equals(-1));
        final result = concatFn.function(['hello', ' ', 'world']);
        expect(result, equals('hello world'));
      });
    });

    group('Function execution', () {
      test('executes with multiple argument types', () {
        final fn = SqlFunction.custom(
          name: 'MIXED_TYPES',
          argumentCount: 3,
          function: (args) => '${args[0]}_${args[1]}_${args[2]}',
        );

        final result = fn.function([42, 'text', 3.14]);
        expect(result, equals('42_text_3.14'));
      });

      test('handles empty argument list', () {
        final fn = SqlFunction.custom(
          name: 'NO_ARGS',
          argumentCount: 0,
          function: (args) => args.isEmpty ? 'empty' : 'not empty',
        );

        final result = fn.function([]);
        expect(result, equals('empty'));
      });

      test('supports Uint8List return type', () {
        final fn = SqlFunction.custom(
          name: 'BYTES',
          argumentCount: 1,
          function: (args) {
            final str = args[0] as String;
            return str.codeUnits;
          },
        );

        final result = fn.function(['AB']);
        expect(result, isA<List<int>>());
      });

      test('supports double return type', () {
        final fn = SqlFunction.custom(
          name: 'SQRT',
          argumentCount: 1,
          function: (args) => (args[0] as num).toDouble() * 0.5,
        );

        final result = fn.function([16]);
        expect(result, equals(8.0));
      });

      test('supports null return value', () {
        final fn = SqlFunction.custom(
          name: 'NULLABLE',
          argumentCount: 1,
          function: (args) => (args[0] as int) == 0 ? null : args[0],
        );

        expect(fn.function([0]), equals(null));
        expect(fn.function([42]), equals(42));
      });
    });

    group('Edge cases', () {
      test('handles very long strings', () {
        final fn = SqlFunction.regexp();
        final longString = 'a' * 10000;
        final result = fn.function(['a+', longString]);
        expect(result, equals(1));
      });

      test('handles Unicode characters', () {
        final fn = SqlFunction.regexp();
        final result = fn.function(['привет', 'привет']);
        expect(result, equals(1));
      });

      test('handles special regex characters in literal string', () {
        final fn = SqlFunction.regexp();
        // r'\$' in a raw string is literally backslash followed by $
        // which matches a literal $
        final result = fn.function([r'\$', r'$']);
        expect(result, equals(1));
      });

      test('handles empty string matching', () {
        final fn = SqlFunction.regexp();
        final result = fn.function([r'^$', '']);
        expect(result, equals(1));
      });

      test('custom function preserves type of arguments', () {
        final fn = SqlFunction.custom(
          name: 'TYPE_CHECK',
          argumentCount: 1,
          function: (args) {
            final arg = args[0];
            if (arg is String) return 'string';
            if (arg is int) return 'int';
            if (arg is double) return 'double';
            return 'other';
          },
        );

        expect(fn.function(['text']), equals('string'));
        expect(fn.function([42]), equals('int'));
        expect(fn.function([3.14]), equals('double'));
      });
    });

    group('Deterministic flag usage', () {
      test('deterministic functions are properly flagged', () {
        final deterministicFn = SqlFunction.custom(
          name: 'UPPER',
          argumentCount: 1,
          function: (args) => (args[0] as String).toUpperCase(),
        );

        expect(deterministicFn.deterministic, isTrue);
      });

      test('non-deterministic functions are properly flagged', () {
        final nonDeterministicFn = SqlFunction.custom(
          name: 'RAND',
          argumentCount: 0,
          function: (args) => DateTime.now().millisecondsSinceEpoch,
          deterministic: false,
        );

        expect(nonDeterministicFn.deterministic, isFalse);
      });

      test('REGEXP is deterministic', () {
        expect(SqlFunction.regexp().deterministic, isTrue);
      });
    });

    group('Real-world use cases', () {
      test('JSON validation function', () {
        final jsonValidateFn = SqlFunction.custom(
          name: 'IS_VALID_JSON',
          argumentCount: 1,
          function: (args) {
            try {
              // Simple check: if string starts with { or [
              final str = args[0] as String;
              return (str.startsWith('{') || str.startsWith('[')) ? 1 : 0;
            } catch (_) {
              return 0;
            }
          },
        );

        expect(jsonValidateFn.function(['{}']), equals(1));
        expect(jsonValidateFn.function(['[]']), equals(1));
        expect(jsonValidateFn.function(['invalid']), equals(0));
      });

      test('slug generation function', () {
        final slugFn = SqlFunction.custom(
          name: 'TO_SLUG',
          argumentCount: 1,
          function: (args) {
            final str = (args[0] as String).toLowerCase();
            return str
                .replaceAll(RegExp('[^a-z0-9]+'), '-')
                .replaceAll(RegExp(r'^-|-$'), '');
          },
        );

        expect(slugFn.function(['Hello World!']), equals('hello-world'));
        expect(slugFn.function(['  Multiple   Spaces  ']),
            equals('multiple-spaces'));
      });

      test('hash function', () {
        final hashFn = SqlFunction.custom(
          name: 'SIMPLE_HASH',
          argumentCount: 1,
          function: (args) {
            final str = args[0].toString();
            var hash = 0;
            for (var i = 0; i < str.length; i++) {
              hash = (hash << 5) - hash + str.codeUnitAt(i);
              hash = hash & hash; // Convert to 32-bit integer
            }
            return hash.abs();
          },
        );

        final hash1 = hashFn.function(['test']);
        final hash2 = hashFn.function(['test']);
        expect(hash1, equals(hash2)); // Same input = same hash
      });
    });

    group('Integration with User model', () {
      /// Email validation with REGEXP function
      test('REGEXP validates user emails', () {
        final regexpFn = SqlFunction.regexp();

        // Valid gmail addresses
        expect(
          regexpFn.function(['.*gmail.*', 'john@gmail.com']),
          equals(1),
        );
        expect(
          regexpFn.function(['.*gmail.*', 'jane@gmail.com']),
          equals(1),
        );

        // Invalid gmail addresses
        expect(
          regexpFn.function(['.*gmail.*', 'user@yahoo.com']),
          equals(0),
        );
      });

      /// Extract domain from email
      test('custom function extracts email domain', () {
        final domainFn = SqlFunction.custom(
          name: 'EMAIL_DOMAIN',
          argumentCount: 1,
          function: (args) {
            final email = args[0] as String;
            final parts = email.split('@');
            return parts.length == 2 ? parts[1] : null;
          },
        );

        expect(domainFn.function(['user@gmail.com']), equals('gmail.com'));
        expect(domainFn.function(['john@example.org']), equals('example.org'));
        expect(domainFn.function(['invalid-email']), equals(null));
      });

      /// Create user slugs from first name
      test('TO_SLUG function creates user URL slugs', () {
        final slugFn = SqlFunction.custom(
          name: 'TO_SLUG',
          argumentCount: 1,
          function: (args) {
            final str = (args[0] as String).toLowerCase();
            return str
                .replaceAll(RegExp('[^a-z0-9]+'), '-')
                .replaceAll(RegExp(r'^-|-$'), '');
          },
        );

        expect(slugFn.function(['Hello World!']), equals('hello-world'));
        expect(slugFn.function(['  Peter  ']), equals('peter'));
        expect(slugFn.function(['Jean-Pierre']), equals('jean-pierre'));
      });

      /// Filter users by age range
      test('custom function checks user age range', () {
        final ageCheckFn = SqlFunction.custom(
          name: 'IN_AGE_RANGE',
          argumentCount: 3,
          function: (args) {
            final age = args[0] as int;
            final minAge = args[1] as int;
            final maxAge = args[2] as int;
            return age >= minAge && age <= maxAge ? 1 : 0;
          },
        );

        // Adult check (18-65)
        expect(ageCheckFn.function([25, 18, 65]), equals(1));
        expect(ageCheckFn.function([17, 18, 65]), equals(0));
        expect(ageCheckFn.function([70, 18, 65]), equals(0));

        // Senior check (65+)
        expect(ageCheckFn.function([70, 65, 120]), equals(1));
      });

      /// Combine first and last names
      test('custom function creates full names', () {
        final fullNameFn = SqlFunction.custom(
          name: 'FULL_NAME',
          argumentCount: 2,
          function: (args) {
            final firstName = args[0] as String;
            final lastName = args[1] as String;
            return '$firstName $lastName'.trim();
          },
        );

        expect(fullNameFn.function(['John', 'Doe']), equals('John Doe'));
        expect(fullNameFn.function(['Mary', 'Smith']), equals('Mary Smith'));
        expect(fullNameFn.function(['', 'Solo']), equals('Solo'));
      });

      /// Calculate user initials
      test('custom function extracts initials', () {
        final initialsFn = SqlFunction.custom(
          name: 'GET_INITIALS',
          argumentCount: 2,
          function: (args) {
            final firstName = (args[0] as String).isNotEmpty
                ? (args[0] as String)[0].toUpperCase()
                : '';
            final lastName = (args[1] as String).isNotEmpty
                ? (args[1] as String)[0].toUpperCase()
                : '';
            return '$firstName$lastName';
          },
        );

        expect(initialsFn.function(['John', 'Doe']), equals('JD'));
        expect(initialsFn.function(['Mary', 'Jane']), equals('MJ'));
        expect(initialsFn.function(['Peter', '']), equals('P'));
      });

      /// Validate gender field
      test('custom function validates gender field', () {
        final genderValidateFn = SqlFunction.custom(
          name: 'VALID_GENDER',
          argumentCount: 1,
          function: (args) {
            final gender = (args[0] as String).toUpperCase();
            return ['M', 'F', 'OTHER'].contains(gender) ? 1 : 0;
          },
        );

        expect(genderValidateFn.function(['M']), equals(1));
        expect(genderValidateFn.function(['F']), equals(1));
        expect(genderValidateFn.function(['Other']), equals(1));
        expect(genderValidateFn.function(['X']), equals(0));
        expect(genderValidateFn.function(['unknown']), equals(0));
      });

      /// Format location from city and country
      test('custom function formats user location', () {
        final locationFn = SqlFunction.custom(
          name: 'FORMAT_LOCATION',
          argumentCount: 2,
          function: (args) {
            final city = args[0] as String;
            final country = args[1] as String;
            return '$city, $country';
          },
        );

        expect(
            locationFn.function(['New York', 'USA']), equals('New York, USA'));
        expect(
            locationFn.function(['Paris', 'France']), equals('Paris, France'));
        expect(locationFn.function(['Moscow', 'Russia']),
            equals('Moscow, Russia'));
      });

      /// Check if user email is from corporate domain
      test('custom function identifies corporate emails', () {
        final corporateFn = SqlFunction.custom(
          name: 'IS_CORPORATE_EMAIL',
          argumentCount: 2,
          function: (args) {
            final email = args[0] as String;
            final corporateDomain = args[1] as String;
            return email.endsWith('@$corporateDomain') ? 1 : 0;
          },
        );

        expect(corporateFn.function(['john@company.com', 'company.com']),
            equals(1));
        expect(
            corporateFn.function(['user@gmail.com', 'company.com']), equals(0));
        expect(
            corporateFn.function(['admin@internal.company.com', 'company.com']),
            equals(0));
      });

      /// Hash password representation (simplified)
      test('custom function hashes user data', () {
        final hashFn = SqlFunction.custom(
          name: 'SIMPLE_HASH',
          argumentCount: 1,
          function: (args) {
            final str = args[0].toString();
            var hash = 0;
            for (var i = 0; i < str.length; i++) {
              hash = (hash << 5) - hash + str.codeUnitAt(i);
              hash = hash & hash;
            }
            return hash.abs();
          },
        );

        // Same input should produce same hash
        final hash1 = hashFn.function(['user@example.com']);
        final hash2 = hashFn.function(['user@example.com']);
        expect(hash1, equals(hash2));

        // Different inputs should (usually) produce different hashes
        final hash3 = hashFn.function(['different@example.com']);
        expect(hash1, isNot(equals(hash3)));
      });

      /// Complex query simulation: Find users with gmail and check age
      test('complex query with multiple custom functions', () {
        final regexpFn = SqlFunction.regexp();
        final ageCheckFn = SqlFunction.custom(
          name: 'IN_RANGE',
          argumentCount: 3,
          function: (args) {
            final value = args[0] as int;
            final min = args[1] as int;
            final max = args[2] as int;
            return value >= min && value <= max ? 1 : 0;
          },
        );

        // Simulate: WHERE email REGEXP '.*gmail.*' AND age BETWEEN 18 AND 65
        const user1Email = 'john@gmail.com';
        const user1Age = 28;
        final isGmailUser = regexpFn.function(['.*gmail.*', user1Email]);
        final isInAgeRange = ageCheckFn.function([user1Age, 18, 65]);

        expect(isGmailUser, equals(1));
        expect(isInAgeRange, equals(1));

        // Non-gmail user
        const user2Email = 'jane@yahoo.com';
        const user2Age = 32;
        final isGmailUser2 = regexpFn.function(['.*gmail.*', user2Email]);
        final isInAgeRange2 = ageCheckFn.function([user2Age, 18, 65]);

        expect(isGmailUser2, equals(0));
        expect(isInAgeRange2, equals(1));
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
