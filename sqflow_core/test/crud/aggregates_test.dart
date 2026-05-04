import 'common.dart';

void main() {
  late SqflowCore<User> userService;

  setUpAll(() {
    initSqflite();
  });

  setUp(() async {
    userService = await createTestService();
  });

  tearDown(() async {
    final db = await userService.database;
    await db.close();
  });

  group('SqflowCore Aggregates:', () {
    test('countAsync without where clause', () async {
      final count = await userService.countAsync();
      final expectedCount = mockUsers.where((u) => u.deletedAt == null).length;
      expect(count, expectedCount); 
    });

    test('countAsync with where clause', () async {
      // Find how many users are active
      final activeCount = await userService.countAsync(
        where: WhereBuilder().eq(UserTable.isActive, 1),
      );
      
      final expectedCount = mockUsers.where((u) => u.deletedAt == null && u.isActive == true).length;
      expect(activeCount, expectedCount);
    });

    test('sumAsync calculates correctly', () async {
      final totalAge = await userService.sumAsync(UserTable.age);
      
      final expectedSum = mockUsers
          .where((u) => u.deletedAt == null && u.age != null)
          .map((u) => u.age!)
          .fold<num>(0, (prev, curr) => prev + curr);
          
      expect(totalAge, expectedSum);
    });

    test('sumAsync with where clause', () async {
      final totalAge = await userService.sumAsync(
        UserTable.age,
        where: WhereBuilder().eq(UserTable.gender, 'M'),
      );
      
      final expectedSum = mockUsers
          .where((u) => u.deletedAt == null && u.age != null && u.gender == 'M')
          .map((u) => u.age!)
          .fold<num>(0, (prev, curr) => prev + curr);
          
      expect(totalAge, expectedSum);
    });

    test('avgAsync calculates correctly', () async {
      final avgAge = await userService.avgAsync(UserTable.age);
      
      final validUsers = mockUsers.where((u) => u.deletedAt == null && u.age != null).toList();
      final expectedSum = validUsers
          .map((u) => u.age!)
          .fold<num>(0, (prev, curr) => prev + curr);
          
      final expectedAvg = expectedSum / validUsers.length;
      
      // Floating point comparison
      expect((avgAge - expectedAvg).abs(), lessThan(0.0001));
    });

    test('minAsync calculates correctly', () async {
      final minAge = await userService.minAsync(UserTable.age);
      
      final expectedMin = mockUsers
          .where((u) => u.deletedAt == null && u.age != null)
          .map((u) => u.age!)
          .reduce((curr, next) => curr < next ? curr : next);
          
      expect(minAge, expectedMin);
    });

    test('maxAsync calculates correctly', () async {
      final maxAge = await userService.maxAsync(UserTable.age);
      
      final expectedMax = mockUsers
          .where((u) => u.deletedAt == null && u.age != null)
          .map((u) => u.age!)
          .reduce((curr, next) => curr > next ? curr : next);
          
      expect(maxAge, expectedMax);
    });
  });
}
