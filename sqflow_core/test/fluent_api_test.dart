import 'mock_users.dart';
import 'models/user.dart';
import 'test_utils.dart';

void main() {
  group('Fluent API vs SqflowCore Instance', () {
    late DB db;
    late SqflowCore<User> userService;

    setUp(() async {
      // 1. Setup the database
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
      );

      // 2. Initialize the global appDb for the static Users class
      appDb = db;

      // 3. Create a traditional service instance
      userService = SqflowCore<User>(dbManager: db, table: usersTable);

      // Seed data
      await userService.insertBatch(mockUsers);
    });

    test('Both approaches should return the same data', () async {
      // Approach A: Traditional SqflowCore instance
      final resultA = await userService.readAll(
        where: WhereBuilder().eq('gender', 'M'),
      );

      // Approach B: New Fluent API via static class
      // Note: Users class is generated in user.sql.g.dart
      final resultB = await Users.where(Users.gender.eq('M')).get();

      expect(resultA.data.length, resultB.length);
      expect(resultA.data.first.id, resultB.first.id);
      print('✅ Both approaches returned ${resultB.length} users.');
    });

    test('Transactions work both ways', () async {
      final newUser = User(
        id: 'new-123',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        phone: '123456',
        gender: 'M',
        city: 'TestCity',
        country: 'TestCountry',
      );

      // Using static class transaction
      await Users.transaction((txn) async {
        await Users.insert(newUser, executor: txn);
      });

      // Verify with instance
      final exists = await userService.readOne('new-123');
      expect(exists, isNotNull);
      expect(exists!.firstName, 'Test');
    });

    test('Complex fluent query', () async {
      // Demonstrate chaining
      final users = await Users.query
          .where(Users.age.gt(25))
          .orderBy(Users.age, descending: true)
          .limit(5)
          .get();

      expect(users.length, lessThanOrEqualTo(5));
      if (users.length > 1) {
        expect(users[0].age! >= users[1].age!, true);
      }
      print('✅ Fluent query returned ${users.length} users over 25.');
    });

    test('SqflowQuery conditional query builders (whereIf and whereNotNull)', () async {
      // Test 1: whereIf true vs false
      final femaleUsers = await Users.query.limit(100).whereIf(true, () => Users.gender.eq('F')).get();
      final skippedUsers = await Users.query.limit(100).whereIf(false, () => Users.gender.eq('F')).get();
      
      expect(femaleUsers.length, greaterThan(0));
      expect(skippedUsers.length, greaterThan(femaleUsers.length)); // since false didn't filter out male users

      // Test 2: whereNotNull with valid vs null value
      final String? validCity = 'Sofia';
      final String? nullCity = null;

      final sofiaUsers = await Users.query.limit(100).whereNotNull(validCity, (val) => Users.city.eq(val)).get();
      final allUsers = await Users.query.limit(100).whereNotNull(nullCity, (val) => Users.city.eq(val)).get();

      for (final u in sofiaUsers) {
        expect(u.city, 'Sofia');
      }
      expect(allUsers.length, greaterThan(sofiaUsers.length));
    });

    test('SqflowQuery terminal aggregates and getWithCount', () async {
      // 1. count()
      final totalSofia = await Users.query.where(Users.city.eq('Sofia')).count();
      expect(totalSofia, greaterThan(0));

      // 2. getWithCount()
      final result = await Users.query.where(Users.city.eq('Sofia')).limit(2).getWithCount();
      expect(result.data.length, lessThanOrEqualTo(2));
      expect(result.count, totalSofia);

      // 3. sum()
      final totalAge = await Users.query.where(Users.city.eq('Sofia')).sum(Users.age);
      expect(totalAge, greaterThan(0));

      // 4. avg()
      final averageAge = await Users.query.where(Users.city.eq('Sofia')).avg(Users.age);
      expect(averageAge, greaterThan(0));

      // 5. min()
      final minAge = await Users.query.where(Users.city.eq('Sofia')).min(Users.age);
      expect(minAge, greaterThan(0));

      // 6. max()
      final maxAge = await Users.query.where(Users.city.eq('Sofia')).max(Users.age);
      expect(maxAge, greaterThan(minAge));
    });

    group('Table Schema', () {
      test('Users columns are correct', () {
        expect(Users.email.name, 'email');
        expect(Users.firstName.name, 'first_name');
      });
    });
  });
}
