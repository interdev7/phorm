// End-to-end generator tests for automatic foreign-key indexes.
//
// A BelongsTo/Join foreign key without an index makes relationship loading
// scan the child table once per parent row; the generator now emits
// `CREATE INDEX IF NOT EXISTS` for those columns by default
// (opt out with `@Schema(indexForeignKeys: false)`).

import 'package:test/test.dart';

import 'gen_common.dart';

const _belongsToSource = '''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(
  tableName: 'posts',
  timestamps: false,
  relationships: [
    BelongsTo(model: 'users', foreignKey: 'user_id'),
  ],
)
class Post {
  @ID()
  final String id;
  @Column()
  final String title;
  const Post(this.id, this.title);
}
''';

void main() {
  test('BelongsTo foreign key gets an index by default', () async {
    final generated = await generateSchema(_belongsToSource);
    expect(
      generated,
      contains(
        'CREATE INDEX IF NOT EXISTS posts_user_id_idx ON posts(user_id);',
      ),
    );
  });

  test('indexForeignKeys: false suppresses the FK index', () async {
    final generated = await generateSchema(
      _belongsToSource.replaceFirst(
        'timestamps: false,',
        'timestamps: false,\n  indexForeignKeys: false,',
      ),
    );
    expect(generated, isNot(contains('posts_user_id_idx')));
  });

  test('duplicate FK columns produce a single index statement', () async {
    final generated = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(
  tableName: 'posts',
  timestamps: false,
  relationships: [
    BelongsTo(model: 'users', foreignKey: 'user_id'),
    Join(model: 'users', foreignKey: 'user_id'),
  ],
)
class Post {
  @ID()
  final String id;
  @Column()
  final String title;
  const Post(this.id, this.title);
}
''');
    expect(
      'posts_user_id_idx'.allMatches(generated),
      hasLength(1),
    );
  });

  test('auto-generated pivot table indexes its related key', () async {
    final generated = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(
  tableName: 'users',
  timestamps: false,
  relationships: [
    ManyToMany(
      model: 'roles',
      pivotTable: 'user_roles',
      foreignKey: 'user_id',
      relatedKey: 'role_id',
      createPivot: true,
    ),
  ],
)
class User {
  @ID()
  final String id;
  @Column()
  final String name;
  const User(this.id, this.name);
}
''');
    // The composite PK (user_id, role_id) covers user_id lookups;
    // role_id gets its own index.
    expect(
      generated,
      contains(
        'CREATE INDEX IF NOT EXISTS user_roles_role_id_idx '
        'ON user_roles(role_id);',
      ),
    );
  });
}
