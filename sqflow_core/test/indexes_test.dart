import 'models/user.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    initSqflite();
  });

  late DB db;
  late SqflowCore<User> userService;

  setUp(() {
    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [usersTable, ordersTable],
    );
    userService = SqflowCore<User>(dbManager: db, table: usersTable);
  });

  tearDown(() async {
    await db.close();
  });

  test('Indices are created in the database', () async {
    final database = await db.database;

    // Check indices for 'users' table
    final userIndexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='users'");
    final userIndexNames = userIndexes.map((i) => i['name'] as String).toList();

    expect(userIndexNames, contains('users_email_idx'));
    expect(userIndexNames, contains('users_first_name_last_name_idx'));

    // Check index for 'orders' table
    final orderIndexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='orders'");
    final orderIndexNames =
        orderIndexes.map((i) => i['name'] as String).toList();

    expect(orderIndexNames, contains('orders_user_id_idx'));
  });

  test('Unique index prevents duplicate emails', () async {
    await userService.insertAsync(User(
      id: 'u1',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: '123',
      gender: 'M',
      city: 'NY',
      country: 'USA',
    ));

    // Inserting another user with same email should fail
    expect(
        () => userService.insertAsync(User(
              id: 'u2',
              firstName: 'Jane',
              lastName: 'Doe',
              email: 'john@example.com',
              phone: '456',
              gender: 'F',
              city: 'LA',
              country: 'USA',
            )),
        throwsException);
  });

  test('Query plan uses index for JOIN relationship', () async {
    final database = await db.database;

    // We want to see if a query for orders by user_id uses the index
    final orderService = SqflowCore(dbManager: db, table: ordersTable);
    final where = WhereBuilder().eq('user_id', 'u1');
    final sql = orderService.getBuildJoinQuery(where: where, explainQueryPlan: true);

    final queryPlan = await database.rawQuery(sql, where.args);

    // SQLite query plan output usually contains "SEARCH TABLE orders USING INDEX orders_user_id_idx"
    final planString = queryPlan.toString();
    expect(planString, contains('USING INDEX orders_user_id_idx'));
  });

  test('Complex relationship query plan uses indices', () async {
    final database = await db.database;

    final where = WhereBuilder().eq('email', 'test@example.com');
    final sql = userService.getBuildJoinQuery(
      where: where,
      include: [Includable.model<Order>()],
      explainQueryPlan: true,
    );

    final complexQueryPlan = await database.rawQuery(sql, where.args);

    final planString = complexQueryPlan.toString();

    // Should use unique index for users.email
    expect(planString, contains('USING INDEX users_email_idx'));

    // Should use index for orders.user_id
    expect(planString, contains('USING INDEX orders_user_id_idx'));
  });
}
