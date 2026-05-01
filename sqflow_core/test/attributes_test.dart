import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';
import 'models/user.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DB db;
  late SqflowCore<User> userService;

  setUp(() async {
    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [usersTable, ordersTable],
    );
    userService = SqflowCore<User>(dbManager: db, table: usersTable);

    final database = await db.database;
    final now = DateTime.now().toIso8601String();
    await database.insert('users', {
      'id': 'u1',
      'first_name': 'John',
      'last_name': 'Doe',
      'email': 'john@example.com',
      'phone': '123456',
      'gender': 'M',
      'city': 'New York',
      'country': 'USA',
      'created_at': now,
      'updated_at': now,
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('Attribute.include should only fetch specified columns', () async {
    final where = WhereBuilder().eq('id', 'u1');
    final sql = userService.getBuildJoinQuery(
      attributes: Attributes.include(['id', 'first_name']),
      where: where,
    );

    final database = await db.database;
    final results = await database.rawQuery(sql, where.args);

    expect(results, hasLength(1));
    expect(results.first.containsKey('first_name'), isTrue);
    expect(results.first.containsKey('last_name'), isFalse);
    expect(results.first.containsKey('email'), isFalse);
  });

  test('Attribute.exclude should fetch all except specified columns', () async {
    final where = WhereBuilder().eq('id', 'u1');
    final sql = userService.getBuildJoinQuery(
      attributes: Attributes.exclude(['email', 'phone']),
      where: where,
    );

    final database = await db.database;
    final results = await database.rawQuery(sql, where.args);

    expect(results, hasLength(1));
    expect(results.first.containsKey('first_name'), isTrue);
    expect(results.first.containsKey('last_name'), isTrue);
    expect(results.first.containsKey('email'), isFalse);
    expect(results.first.containsKey('phone'), isFalse);
  });

  test('Include should support Attribute filtering for relationships',
      () async {
    final where = WhereBuilder().eq('id', 'u1');
    final sql = userService.getBuildJoinQuery(
      attributes: Attributes.include(['id', 'first_name']),
      include: [
        Includable.model<Order>(attributes: Attributes.include(['total']))
      ],
      where: where,
    );

    // The SQL should contain a subquery for orders with only 'total'
    expect(sql, contains("'total', orders.total"));
    expect(sql, isNot(contains("'id', orders.id")));

    final database = await db.database;
    final now = DateTime.now().toIso8601String();
    await database.insert('orders', {
      'id': 1,
      'total': 100,
      'user_id': 'u1',
      'created_at': now,
      'updated_at': now
    });

    final results = await database.rawQuery(sql, where.args);
    expect(results, hasLength(1));

    final ordersJson = results.first['orders'] as String;
    expect(ordersJson, contains('"total":100'));
    expect(ordersJson, isNot(contains('"id":1')));
  });
}

// Add a helper to access _buildJoinQuery for testing if needed,
// or just test through readAsync and check what fails.
// Since _buildJoinQuery is private, I'll add a public getter or just test readAsync.

extension SqflowCoreTestExt on SqflowCore {
  String getBuildJoinQuery({
    List<String>? columns,
    Attributes? attributes,
    List<Includable>? include,
    WhereBuilder? where,
  }) {
    return (this as dynamic).buildJoinQuery(
      columns: columns,
      attributes: attributes,
      include: include,
      where: where,
    ) as String;
  }
}
