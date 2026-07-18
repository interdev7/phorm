// End-to-end generator tests for the positional row binder emission
// (Table.rowBinder / _$Phorm<Class>RowBinder) used by the core's columnar
// read fast path.

import 'package:test/test.dart';

import 'gen_common.dart';

const _source = '''
import 'package:phorm_annotations/phorm_annotations.dart';

enum Role { admin, user }

@Schema(
  tableName: 'posts',
  relationships: [
    BelongsTo(model: 'users', foreignKey: 'user_id'),
  ],
)
class Post {
  @ID()
  final String id;
  @Column()
  final String title;
  @Column()
  final int views;
  @Column()
  final bool published;
  @Column()
  final Role role;
  const Post(this.id, this.title, this.views, this.published, this.role);
}
''';

void main() {
  late String generated;

  setUpAll(() async {
    generated = await generateSchema(_source);
  });

  test('emits the binder function with hoisted column indices', () {
    expect(
      generated,
      contains(
        RegExp(
          r'Post Function\(List<Object\?> row\) _\$PhormPostRowBinder\(\s*'
          r'Map<String, int> columnIndex\s*,?\s*\)',
        ),
      ),
    );
    expect(generated, contains("columnIndex['id']"));
    expect(generated, contains("columnIndex['title']"));
    expect(generated, contains("columnIndex['views']"));
  });

  test('wires the binder into the generated Table', () {
    expect(generated, contains(r'rowBinder: _$PhormPostRowBinder,'));
    expect(generated, contains('super.rowBinder,'));
  });

  test('mirrors fromJson conversions positionally', () {
    // enum
    expect(generated, contains('Role.values.byName('));
    // bool 0/1 handling comes from the shared value generator
    expect(generated, contains('== 1'));
    // timestamps cascade present in the binder
    expect(
      '..createdAt ='.allMatches(generated).length,
      greaterThanOrEqualTo(2), // fromJson + binder
    );
  });

  test('values go through phormDecodeJson for JSON-column parity', () {
    expect(generated, contains('phormDecodeJson(row[i])'));
  });

  test('generic models do not get a binder', () async {
    const genericSource = '''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'boxes', timestamps: false)
class Box<T> {
  @ID()
  final String id;
  @Column()
  final String label;
  const Box(this.id, this.label);
}
''';
    final out = await generateSchema(genericSource);
    expect(out, isNot(contains('RowBinder')));
    expect(out, isNot(contains('rowBinder:')));
  });
}
