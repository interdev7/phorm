import 'package:flutter_test/flutter_test.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

import 'models/user.dart';

User _user(String id) => User(
  id: id,
  firstName: 'Observer',
  lastName: 'Test',
  email: '$id@test.com',
  phone: '+359888000000',
  gender: 'M',
  city: 'City',
  country: 'Country',
  isActive: true,
  isVerified: false,
);

void main() {
  group('DB.onQuery observer', () {
    late List<QueryEvent> events;
    late DB db;
    late PhormCore<User> users;

    setUp(() async {
      events = [];
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
        logger: null,
        onQuery: events.add,
      );
      users = PhormCore<User>(dbManager: db, table: usersTable);
    });

    tearDown(() => db.close());

    test('receives events for successful operations', () async {
      await users.insert(_user('obs_1'));
      await users.readOne('obs_1');

      expect(events, isNotEmpty);
      final insert = events.firstWhere((e) => e.sql.contains('INSERT'));
      expect(insert.failed, isFalse);
      expect(insert.duration, greaterThanOrEqualTo(Duration.zero));
      expect(events.any((e) => e.sql.contains('SELECT')), isTrue);
    });

    test('works independently of logQueries (off by default)', () async {
      // logQueries is false here, but events still arrive.
      await users.insert(_user('obs_2'));
      expect(events, isNotEmpty);
    });

    test('reports failed operations with error and stack trace', () async {
      await users.insert(_user('obs_3'));
      events.clear();

      // Duplicate primary key → constraint violation.
      await expectLater(users.insert(_user('obs_3')), throwsA(anything));

      final failed = events.where((e) => e.failed).toList();
      expect(failed, hasLength(1));
      expect(failed.single.error, isNotNull);
      expect(failed.single.stackTrace, isNotNull);
      expect(failed.single.toString(), contains('failed'));
    });

    test('marks slow operations via the slowQueryThreshold', () async {
      final slowDb = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [usersTable],
        singleInstance: false,
        logger: null,
        slowQueryThreshold: Duration.zero, // everything is "slow"
        onQuery: events.add,
      );
      final slowUsers = PhormCore<User>(dbManager: slowDb, table: usersTable);

      await slowUsers.insert(_user('obs_4'));
      expect(events.any((e) => e.isSlow), isTrue);
      expect(events.firstWhere((e) => e.isSlow).toString(), contains('slow'));

      await slowDb.close();
    });
  });
}
