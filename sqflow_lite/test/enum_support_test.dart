import 'package:flutter_test/flutter_test.dart';
import 'package:sqflow/sqflow.dart';
import 'package:sqflow_lite/sqflow_lite.dart';
import 'models/enum_test_model.dart';

void main() {
  late DB db;

  setUp(() {
    db = DB(
      databaseName: ':memory:',
      version: 1,
      tables: [enum_postsTable],
    );
    appDb = db; // Assign to global appDb needed for generated pluralized service
  });

  tearDown(() async {
    await db.close();
  });

  test('Enum serialization, insertion, and retrieval', () async {
    // 1. Create a record with enums
    final post = EnumPost(
      id: 1,
      title: 'First Post',
      status: PostStatus.published,
      optionalStatus: PostStatus.draft,
    );

    // Insert using the service
    await EnumPosts.insert(post);

    // Retrieve back from the database
    final retrieved = await EnumPosts.readOne(1);

    expect(retrieved, isNotNull);
    expect(retrieved!.id, 1);
    expect(retrieved.title, 'First Post');
    expect(retrieved.status, PostStatus.published);
    expect(retrieved.optionalStatus, PostStatus.draft);

    // 2. Create another record with null optional enum
    final post2 = EnumPost(
      id: 2,
      title: 'Second Post',
      status: PostStatus.archived,
      optionalStatus: null,
    );

    await EnumPosts.insert(post2);

    final retrieved2 = await EnumPosts.readOne(2);
    expect(retrieved2, isNotNull);
    expect(retrieved2!.status, PostStatus.archived);
    expect(retrieved2.optionalStatus, isNull);

    // 3. Test WhereBuilder with enum value
    final queryResult = await EnumPosts.readAll(
      where: WhereBuilder().eq(EnumPosts.status, PostStatus.published),
    );

    expect(queryResult.data, hasLength(1));
    expect(queryResult.data.first.id, 1);
  });
}
