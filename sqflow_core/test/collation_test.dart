import 'models/collation_test.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    initSqflite();
  });

  group('String Collation', () {
    late DB db;
    late SqflowCore<CollationTest> service;

    setUp(() async {
      db = DB(
        databaseName: ':memory:',
        version: 1,
        tables: [collation_testsTable],
        singleInstance: false,
      );
      appDb = db;
      service =
          SqflowCore<CollationTest>(dbManager: db, table: collation_testsTable);

      await service.insertAsync(CollationTest(
        id: '1',
        nameNoCase: 'Alice',
        nameBinary: 'Alice',
      ));
    });

    test('NOCASE should be case-insensitive', () async {
      final results =
          await CollationTests.where(CollationTests.nameNoCase.eq('alice'))
              .get();

      expect(results.length, 1,
          reason: 'NOCASE should match "Alice" with "alice"');
      expect(results.first.nameNoCase, 'Alice');
    });

    test('BINARY should be case-sensitive', () async {
      final results =
          await CollationTests.where(CollationTests.nameBinary.eq('alice'))
              .get();

      expect(results.length, 0,
          reason: 'BINARY should NOT match "Alice" with "alice"');

      final exactMatch =
          await CollationTests.where(CollationTests.nameBinary.eq('Alice'))
              .get();
      expect(exactMatch.length, 1);
    });

    test('Sorting with NOCASE', () async {
      await service.insertAsync(CollationTest(
        id: '2',
        nameNoCase: 'bob',
        nameBinary: 'bob',
      ));
      await service.insertAsync(CollationTest(
        id: '3',
        nameNoCase: 'Charlie',
        nameBinary: 'Charlie',
      ));

      // Sorting nameNoCase (Alice, bob, Charlie)
      // If NOCASE works, it should be Alice, bob, Charlie (or Alice, Charlie, bob depending on order, but case won't mess it up)
      // Actually SQLite NOCASE sort order: A, B, C, a, b, c -> wait, NOCASE treats them as same.

      final sorted =
          await CollationTests.query.orderBy(CollationTests.nameNoCase).get();

      final names = sorted.map((e) => e.nameNoCase).toList();
      expect(names, ['Alice', 'bob', 'Charlie']);
    });
  });
}
