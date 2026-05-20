import 'package:sqflow_core/sqflow_core.dart';
import 'package:test/test.dart';

import 'models/nested_object_test_model.dart';

void main() {
  late DB db;

  setUp(() async {
    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [users_with_locationTable],
    );
    appDb = db;
    await db.database; // trigger init
  });

  tearDown(() async {
    await db.close();
  });

  test('Should insert and ignore non-column fields, but error on read due to missing fields', () async {
    final user = UserWithLocation(
      id: 1,
      name: 'Dart',
      location: Location(lat: 10.0, lng: 20.0),
      age: 30,
    );

    // Insert should work, ignoring location and age
    await UsersWithLocation.insert(user);

    // Read should succeed, but location and age will be null because they are not in DB
    final loadedUser = await UsersWithLocation.readOne(1);
    expect(loadedUser, isNotNull);
    expect(loadedUser!.name, 'Dart');
    expect(loadedUser.location, isNull);
    expect(loadedUser.age, isNull);
  });
}
