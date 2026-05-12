# Seeders & Factories

For enterprise applications, it is essential to have a way to populate the database with initial or test data. SQFlow provides `Seeder` and `Factory` interfaces to streamline this process.

---

## Factories

A `Factory` is used to generate mock data for your models. This is particularly useful for unit testing or when you need to generate a large amount of random data for UI development.

### Defining a Factory

Implement the `Factory<T>` interface and define the `create()` method.

```dart
import 'package:sqflow_core/sqflow_core.dart';
import 'package:faker/faker.dart'; // Optional: using a library for random data

class UserFactory extends Factory<User> {
  final _faker = Faker();

  @override
  User create() {
    return User(
      id: _faker.guid.guid(),
      firstName: _faker.person.firstName(),
      lastName: _faker.person.lastName(),
      email: _faker.internet.email(),
      gender: 'M',
      createdAt: DateTime.now(),
    );
  }
}
```

### Using a Factory

```dart
final userFactory = UserFactory();

// Create one instance
User user = userFactory.create();

// Create 10 instances
List<User> users = userFactory.createMany(10);
```

---

## Seeders

A `Seeder` is a class responsible for populating specific tables in the database.

### Defining a Seeder

Implement the `Seeder` interface and define the `run(DB db)` method. Inside this method, you can use `SqflowCore` services to insert data.

```dart
class UserSeeder extends Seeder {
  @override
  Future<void> run(DB db) async {
    // Initialize the service for the model you want to seed
    final userService = SqflowCore<User>(dbManager: db, table: usersTable);
    
    // Use a factory to generate data
    final users = UserFactory().createMany(50);
    
    // Insert into DB
    await userService.insertBatchAsync(users);
  }
}
```

---

## Executing Seeders

You can execute multiple seeders using the `db.seed()` method. This is typically done during app initialization or in a test `setUp` block.

```dart
final db = DB(
  databaseName: 'app.db',
  version: 1,
  tables: [usersTable, postsTable],
);

// Run seeders
await db.seed([
  UserSeeder(),
  PostSeeder(),
]);
```

---

## Recommended Workflow

1.  **Define Factories** for all your major models.
2.  **Create Seeders** that use these factories to populate the DB.
3.  **Run `db.seed()`** when the app starts in "Debug Mode" or when running integration tests.

> [!TIP]
> Use seeders to create a "Golden State" of your database that includes common scenarios (e.g., an admin user, a user with many posts, a user with no posts) to make manual testing much faster.
---

## Testing Seeders & Factories

It is a good practice to verify that your factories generate correct data and that your seeders populate the database as expected.

### Unit Testing a Factory

```dart
test('UserFactory creates models with correct incrementing logic', () {
  final userFactory = UserFactory();
  final users = userFactory.createMany(3);

  expect(users.length, 3);
  expect(users[0].firstName, contains('User 1'));
  expect(users[2].firstName, contains('User 3'));
});
```

### Testing a Seeder with In-Memory DB

Use an in-memory database to verify that the seeder correctly inserts data.

```dart
test('UserSeeder populates the database', () async {
  final db = DB(databaseName: ':memory:', version: 1, tables: [usersTable]);
  final userService = SqflowCore<User>(dbManager: db, table: usersTable);

  // Run seeder
  await db.seed([UserSeeder()]);

  // Verify
  expect(await userService.countAsync(), 50);
});
```
