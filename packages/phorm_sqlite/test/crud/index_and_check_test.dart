import 'common.dart';

void main() {
  group('Indexes and CHECK constraint tests:', () {
    test('Indexes exist and have correct columns', () async {
      final service = await createTestService();
      final db = await service.dbManager.executor;

      final idxList = await db.rawQuery("PRAGMA index_list('users')");
      final indexNames = idxList.map((r) => r['name'] as String).toList();

      expect(indexNames, contains('users_email_idx'));
      expect(indexNames, contains('users_first_name_last_name_idx'));

      final info = await db.rawQuery(
        "PRAGMA index_info('users_first_name_last_name_idx')",
      );
      final cols = info.map((r) => r['name'] as String).toList();
      expect(cols, equals(['first_name', 'last_name']));
    });

    test('CHECK constraint rejects invalid gender', () async {
      final service = await createTestService();

      final db = await service.dbManager.executor;

      expect(
        () async => await db.insert('users', {
          'id': 'bad_gender_001',
          'first_name': 'Bad',
          'last_name': 'Gender',
          'email': 'bad.gender@example.com',
          'phone': '+359000000000',
          'birth_date': null,
          'age': 99,
          'gender': 'X', // invalid per CHECK
          'city': 'Nowhere',
          'country': 'Bulgaria',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
        throwsA(
          isA<PhormCHECKValidatorException>()
              .having((e) => e.table, 'table', 'users')
              .having((e) => e.column, 'column', 'gender')
              .having((e) => e.constraint, 'constraint', 'gender_check'),
        ),
      );
    });
  });
}
