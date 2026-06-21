import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'models/migration_user.dart';

// Mock Model Factory
class MigrationUserFactory extends Factory<MigrationUser> {
  int _counter = 0;

  @override
  MigrationUser create() {
    _counter++;
    return MigrationUser(id: 'user_$_counter', name: 'User $_counter');
  }
}

// Mock Seeder
class MigrationUserSeeder extends Seeder {
  @override
  Future<void> run(PhormDatabase db) async {
    final userService = PhormCore<MigrationUser>(
      dbManager: db,
      table: migration_usersTable,
    );
    final userFactory = MigrationUserFactory();

    // Seed 5 users
    await userService.insertBatch(userFactory.createMany(5));
  }
}

void main() {
  late DB db;
  late PhormCore<MigrationUser> userService;

  setUp(() async {
    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [migration_usersTable],
      singleInstance: false,
    );
    userService = PhormCore<MigrationUser>(
      dbManager: db,
      table: migration_usersTable,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Seeders & Factories', () {
    test('Factory creates models with predefined logic', () {
      final userFactory = MigrationUserFactory();
      final users = userFactory.createMany(3);

      expect(users.length, 3);
      expect(users[0].name, 'User 1');
      expect(users[1].name, 'User 2');
      expect(users[2].name, 'User 3');
      expect(users[0].id, 'user_1');
    });

    test('db.seed() executes seeders and populates data', () async {
      // Initially empty
      final initialCount = await userService.count();
      expect(initialCount, 0);

      // Run seeding
      await db.seed([MigrationUserSeeder()]);

      // Verify 5 users were inserted
      final countAfterSeed = await userService.count();
      expect(countAfterSeed, 5);

      final result = await userService.readAll();
      expect(result.data[0].name, 'User 1');
      expect(result.data[4].name, 'User 5');
    });

    test('db.seed() can run multiple seeders in sequence', () async {
      await db.seed([
        MigrationUserSeeder(), // inserts 1-5
        _SpecialSeeder(), // inserts special
      ]);

      expect(await userService.count(), 6);
      expect(await userService.exists('special_id'), isTrue);
    });
  });
}

class _SpecialSeeder extends Seeder {
  @override
  Future<void> run(PhormDatabase db) async {
    final userService = PhormCore<MigrationUser>(
      dbManager: db,
      table: migration_usersTable,
    );
    await userService.insert(
      MigrationUser(id: 'special_id', name: 'Special User'),
    );
  }
}
