import 'common.dart';

void main() {
  group('WhereBuilder Tests:', () {
    test('Basic conditions (eq, gt, lt)', () {
      final where =
          WhereBuilder().eq('is_active', 1).gt('age', 30).lt('age', 50);

      expect(where.build(), 'is_active = ? AND age > ? AND age < ?');
      expect(where.args, [1, 30, 50]);
    });

    test('LIKE and ILIKE conditions', () {
      final where = WhereBuilder()
          .like('email', '%gmail.com')
          .ilike('first_name', '%anna%');

      expect(where.build(), 'email LIKE ? AND LOWER(first_name) LIKE LOWER(?)');
      expect(where.args, ['%gmail.com', '%anna%']);
    });

    test('IN and NOT IN conditions', () {
      final where = WhereBuilder().inList(
          'city', ['Sofia', 'Plovdiv', 'Varna']).notInList('gender', ['Other']);

      expect(where.build(), 'city IN (?, ?, ?) AND gender NOT IN (?)');
      expect(where.args, ['Sofia', 'Plovdiv', 'Varna', 'Other']);
    });

    test('NULL checks', () {
      final where = WhereBuilder().isNull('deleted_at').isNotNull('updated_at');

      expect(where.build(), 'deleted_at IS NULL AND updated_at IS NOT NULL');
      expect(where.args, isEmpty);
    });

    test('AND grouping', () {
      final where = WhereBuilder().eq('country', 'Bulgaria').andGroup((wg) {
        wg.gt('age', 18).lt('age', 65);
      }).eq('is_verified', 1);

      expect(
        where.build(),
        'country = ? AND (age > ? AND age < ?) AND is_verified = ?',
      );
      expect(where.args, ['Bulgaria', 18, 65, 1]);
    });

    test('OR grouping', () {
      final where = WhereBuilder().eq('is_active', 1).orGroup((wg) {
        wg.eq('city', 'Sofia').eq('city', 'Plovdiv');
      });

      expect(
        where.build(),
        'is_active = ? AND (city = ? OR city = ?)',
      );
      expect(where.args, [1, 'Sofia', 'Plovdiv']);
    });

    test('Nested groups', () {
      final where = WhereBuilder().andGroup((ag) {
        ag.eq('gender', 'M').gt('age', 40);
      }).orGroup((og) {
        og.eq('city', 'Sofia').eq('city', 'Varna');
      });

      expect(
        where.build(),
        '(gender = ? AND age > ?) AND (city = ? OR city = ?)',
      );
      expect(where.args, ['M', 40, 'Sofia', 'Varna']);
    });

    test('Raw SQL conditions', () {
      final where = WhereBuilder().raw('LENGTH(first_name) > ?', [3]).raw(
          'SUBSTR(last_name, 1, 1) = ?', ['S']);

      expect(where.build(),
          'LENGTH(first_name) > ? AND SUBSTR(last_name, 1, 1) = ?');
      expect(where.args, [3, 'S']);
    });

    test('LENGTH and SUBSTR helper methods', () {
      final where = WhereBuilder()
          .lengthEq('first_name', 5)
          .lengthNe('last_name', 3)
          .lengthGt('nickname', 2)
          .lengthGte('alias', 4)
          .lengthLt('short', 10)
          .lengthLte('tiny', 1)
          .substrEq('last_name', 1, 1, 'S')
          .substrLike('email', 1, 3, '%@g')
          .substrIlike('first_name', 1, 2, 'jo');

      expect(
        where.build(),
        'LENGTH(first_name) = ? AND LENGTH(last_name) != ? AND LENGTH(nickname) > ? AND LENGTH(alias) >= ? AND LENGTH(short) < ? AND LENGTH(tiny) <= ? AND SUBSTR(last_name, ?, ?) = ? AND SUBSTR(email, ?, ?) LIKE ? AND LOWER(SUBSTR(first_name, ?, ?)) LIKE LOWER(?)',
      );

      expect(
        where.args,
        [5, 3, 2, 4, 10, 1, 1, 1, 'S', 1, 3, '%@g', 1, 2, 'jo'],
      );
    });

    test('hasConditionOn check', () {
      final where = WhereBuilder()
          .eq('age', 25)
          .like('email', '%@gmail.com')
          .orGroup((og) {
        og.eq('city', 'Sofia').eq('city', 'Plovdiv');
      });

      expect(where.hasConditionOn('age'), true);
      expect(where.hasConditionOn('email'), true);
      expect(where.hasConditionOn('city'), true);
      expect(where.hasConditionOn('nonexistent'), false);
    });

    test('Builder copy', () {
      final original =
          WhereBuilder().eq('is_active', 1).like('email', '%gmail.com');

      final copy = original.copy();

      expect(copy.build(), original.build());
      expect(copy.args, original.args);

      // Modifying the copy should not affect the original
      copy.eq('city', 'Sofia');
      expect(original.hasConditionOn('city'), false);
      expect(copy.hasConditionOn('city'), true);
    });

    test('clone() (alias for copy)', () {
      final original = WhereBuilder().eq('status', 'active');
      final clone = original.clone();

      expect(clone.build(), original.build());
      expect(clone.args, original.args);

      clone.gt('age', 18);
      expect(original.hasConditionOn('age'), false);
      expect(clone.hasConditionOn('age'), true);
    });

    test('Invalid column name in WhereBuilder', () {
      expect(
        () => WhereBuilder().eq('invalid-column', 'value'),
        throwsArgumentError,
      );

      expect(
        () => WhereBuilder().eq('123invalid', 'value'),
        throwsArgumentError,
      );
    });

    test('WhereBuilder with null values', () {
      final where = WhereBuilder()
          .eq('column1', null) // Should be ignored
          .isNull('column2')
          .eqIfNotNull('column3', null)
          .eqIfNotNull('column4', '');

      expect(where.build(), 'column2 IS NULL');
      expect(where.args, isEmpty);
    });
    test('Typed columns from Users', () {
      final where = WhereBuilder()
          .eq(Users.isActive, 1)
          .like(Users.email, '%gmail.com')
          .gt(Users.age, 30)
          .lengthEq(Users.firstName, 5);

      expect(where.build(),
          'users.is_active = ? AND users.email LIKE ? AND users.age > ? AND LENGTH(users.first_name) = ?');
      expect(where.args, [1, '%gmail.com', 30, 5]);
    });

    test('WhereBuilders.softDelete factory', () {
      final where = WhereBuilders.softDelete(
        paranoid: true,
        withDeleted: false,
        onlyDeleted: false,
      );
      expect(where.build(), 'deleted_at IS NULL');

      final onlyDeleted = WhereBuilders.softDelete(
        paranoid: true,
        onlyDeleted: true,
      );
      expect(onlyDeleted.build(), 'deleted_at IS NOT NULL');

      final withDeleted = WhereBuilders.softDelete(
        paranoid: true,
        withDeleted: true,
      );
      expect(withDeleted.isEmpty, true);
    });

    test('WhereBuilders.multiColumnSearch factory', () {
      final where = WhereBuilders.multiColumnSearch(
        'john',
        ['first_name', 'last_name', 'email'],
        caseSensitive: true,
      );

      expect(
        where.build(),
        '(first_name LIKE ? OR last_name LIKE ? OR email LIKE ?)',
      );
      expect(where.args, ['%john%', '%john%', '%john%']);

      final caseInsensitive = WhereBuilders.multiColumnSearch(
        'john',
        ['first_name', 'last_name'],
        caseSensitive: false,
      );
      expect(
        caseInsensitive.build(),
        '(LOWER(first_name) LIKE LOWER(?) OR LOWER(last_name) LIKE LOWER(?))',
      );
    });

    test('WhereBuilderExtensions new conditional methods', () {
      // 1. eqIfNotNull with PhormColumn and Object
      final where1 = WhereBuilder()
          .eqIfNotNull(Users.email, 'test@example.com')
          .eqIfNotNull(Users.firstName, null)
          .eqIfNotNull(Users.lastName, '');
      expect(where1.build(), 'users.email = ?');
      expect(where1.args, ['test@example.com']);

      // 2. inListIfNotEmpty with PhormColumn
      final where2 = WhereBuilder()
          .inListIfNotEmpty(Users.city, ['Sofia', 'Plovdiv'])
          .inListIfNotEmpty(Users.country, null)
          .inListIfNotEmpty(Users.gender, []);
      expect(where2.build(), 'users.city IN (?, ?)');
      expect(where2.args, ['Sofia', 'Plovdiv']);

      // 3. dateRangeIfProvided with PhormColumn
      final now = DateTime(2026, 5, 19);
      final where3 =
          WhereBuilder().dateRangeIfProvided(Users.createdAt, now, null);
      expect(where3.build(), 'users.created_at >= ?');
      expect(where3.args, [now.toIso8601String()]);

      // 4. addIf
      final where4 = WhereBuilder()
          .addIf(true, (w) => w.eq(Users.isActive, true))
          .addIf(false, (w) => w.eq(Users.gender, 'F'));
      expect(where4.build(), 'users.is_active = ?');
      expect(where4.args, [1]);

      // 5. addNotNull
      final String? search = 'Sofia';
      final String? country = null;
      final where5 = WhereBuilder()
          .addNotNull(search, (w, val) => w.eq(Users.city, val))
          .addNotNull(country, (w, val) => w.eq(Users.country, val));
      expect(where5.build(), 'users.city = ?');
      expect(where5.args, ['Sofia']);
    });
  });
}
