// End-to-end generator tests for @ManyToMany pivot-table generation.
//
// Unlike the phorm_sqlite integration tests (which hand-write the pivot DDL
// into the schema string), these run the REAL builder over an in-memory source
// and assert that the generated .sql.g.dart actually contains the pivot table.
// This proves the pivot is materialized at build_runner time, inside .g.dart.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:phorm_generator/builder.dart';
import 'package:test/test.dart';

/// Runs the standalone schema builder over [source] and returns the generated
/// `.sql.g.dart` content for `pkg|lib/model.dart`.
Future<String> generate(String source) async {
  final builder = standaloneSqlSchemaBuilder(BuilderOptions.empty);
  final writer = InMemoryAssetWriter();

  await testBuilder(
    builder,
    {'pkg|lib/model.dart': source},
    writer: writer,
    reader: await PackageAssetReader.currentIsolate(),
  );

  final output = writer.assets[AssetId('pkg', 'lib/model.sql.g.dart')];
  return output == null ? '' : String.fromCharCodes(output);
}

void main() {
  test('createPivot: true emits a minimal pivot CREATE TABLE', () async {
    final generated = await generate('''
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

    expect(generated, contains('CREATE TABLE IF NOT EXISTS user_roles'));
    expect(generated, contains('user_id TEXT NOT NULL'));
    expect(generated, contains('role_id TEXT NOT NULL'));
    expect(generated, contains('PRIMARY KEY (user_id, role_id)'));
    // Minimal pivot must NOT carry foreign-key constraints.
    expect(generated, isNot(contains('FOREIGN KEY')));
  });

  test('pivotForeignKeys: true adds FK constraints with ON DELETE CASCADE',
      () async {
    final generated = await generate('''
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
      pivotForeignKeys: true,
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

    expect(generated, contains('CREATE TABLE IF NOT EXISTS user_roles'));
    expect(
      generated,
      contains(
        'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE',
      ),
    );
    expect(
      generated,
      contains(
        'FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE',
      ),
    );
  });

  test('createPivot defaults to false — no pivot table emitted', () async {
    final generated = await generate('''
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

    // The model table is still generated, but no pivot table.
    expect(generated, contains('CREATE TABLE users'));
    expect(generated, isNot(contains('user_roles')));
  });
}
