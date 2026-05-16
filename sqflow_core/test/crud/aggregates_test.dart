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

  group('SqflowCore Aggregates:', () {
    test('count without where clause', () async {
      final count = await userService.count();
      final expectedCount = mockUsers.where((u) => u.deletedAt == null).length;
      expect(count, expectedCount);
    });

    test('count with where clause', () async {
      // Find how many users are active
      final activeCount = await userService.count(
        where: WhereBuilder().eq(Users.isActive, true),
      );

      final expectedCount = mockUsers
          .where((u) => u.deletedAt == null && u.isActive == true)
          .length;
      expect(activeCount, expectedCount);
    });

    test('sum calculates correctly', () async {
      final totalAge = await userService.sum(Users.age);

      final expectedSum = mockUsers
          .where((u) => u.deletedAt == null && u.age != null)
          .map((u) => u.age!)
          .fold<num>(0, (prev, curr) => prev + curr);

      expect(totalAge, expectedSum);
    });

    test('sum with where clause', () async {
      final totalAge = await userService.sum(
        Users.age,
        where: WhereBuilder().eq(Users.gender, 'M'),
      );

      final expectedSum = mockUsers
          .where((u) => u.deletedAt == null && u.age != null && u.gender == 'M')
          .map((u) => u.age!)
          .fold<num>(0, (prev, curr) => prev + curr);

      expect(totalAge, expectedSum);
    });

    test('avg calculates correctly', () async {
      final avgAge = await userService.avg(Users.age);

      final validUsers =
          mockUsers.where((u) => u.deletedAt == null && u.age != null).toList();
      final expectedSum = validUsers
          .map((u) => u.age!)
          .fold<num>(0, (prev, curr) => prev + curr);

      final expectedAvg = expectedSum / validUsers.length;

      // Floating point comparison
      expect((avgAge - expectedAvg).abs(), lessThan(0.0001));
    });

    test('min calculates correctly', () async {
      final minAge = await userService.min(Users.age);

      final expectedMin = mockUsers
          .where((u) => u.deletedAt == null && u.age != null)
          .map((u) => u.age!)
          .reduce((curr, next) => curr < next ? curr : next);

      expect(minAge, expectedMin);
    });

    test('max calculates correctly', () async {
      final maxAge = await userService.max(Users.age);

      final expectedMax = mockUsers
          .where((u) => u.deletedAt == null && u.age != null)
          .map((u) => u.age!)
          .reduce((curr, next) => curr > next ? curr : next);

      expect(maxAge, expectedMax);
    });
  });
}
