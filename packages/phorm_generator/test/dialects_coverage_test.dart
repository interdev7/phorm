import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:phorm_generator/src/generators/function_generator.dart';
import 'package:phorm_generator/src/generators/schema_generator.dart';
import 'package:test/test.dart';

import 'gen_common.dart';

// A model body covering every core type, reused across dialects.
String _model(String dialect) => '''
import 'dart:typed_data';
import 'package:phorm_annotations/phorm_annotations.dart';

enum E { a, b }

@Schema(tableName: 'm', dialect: SqlDialectKind.$dialect)
class M {
  @ID(autoIncrement: true)
  final int id;
  @Column(defaultValue: true)
  final bool flag;
  @Column()
  final double d;
  @Column()
  final String s;
  @Column()
  final num n;
  @Column()
  final DateTime dt;
  @Column()
  final Uint8List bytes;
  @Column()
  final Duration dur;
  @Column()
  final BigInt big;
  @Column()
  final Uri uri;
  @Column()
  final E e;
  const M(this.id, this.flag, this.d, this.s, this.n, this.dt, this.bytes,
      this.dur, this.big, this.uri, this.e);
}
''';

void main() {
  test('mysql dialect maps all core types', () async {
    final out = await generateSchema(_model('mysql'));
    expect(out, contains('CREATE TABLE m'));
    expect(out, contains('INT')); // int
    expect(out, contains('TINYINT(1)')); // bool
    expect(out, contains('DATETIME')); // DateTime / timestamps
    expect(out, contains('AUTO_INCREMENT'));
  });

  test('postgres dialect maps all core types', () async {
    final out = await generateSchema(_model('postgres'));
    expect(out, contains('CREATE TABLE m'));
    expect(out, contains('DOUBLE PRECISION')); // double
    expect(out, contains('BOOLEAN')); // bool
    expect(out, contains('TIMESTAMP')); // DateTime
    expect(out, contains('BYTEA')); // Uint8List
    expect(out, contains('DEFAULT TRUE')); // bool default formatting
  });

  group('dialect strategy factories and names', () {
    test('SchemaGenerator.fromKind returns each dialect', () {
      expect(SchemaGenerator.fromKind(SqlDialectKind.sqlite).name, 'sqlite');
      expect(SchemaGenerator.fromKind(SqlDialectKind.postgres).name, 'postgres');
      expect(SchemaGenerator.fromKind(SqlDialectKind.mysql).name, 'mysql');
    });

    test('FunctionGenerator.fromKind returns each dialect', () {
      expect(FunctionGenerator.fromKind(SqlDialectKind.sqlite).name, 'sqlite');
      expect(
        FunctionGenerator.fromKind(SqlDialectKind.postgres).name,
        'postgres',
      );
      expect(FunctionGenerator.fromKind(SqlDialectKind.mysql).name, 'mysql');
    });
  });

  group('scaffold function generators', () {
    test('mysql/postgres emit a TODO for non-empty, empty for empty', () async {
      final mysql = FunctionGenerator.fromKind(SqlDialectKind.mysql);
      final pg = FunctionGenerator.fromKind(SqlDialectKind.postgres);

      // Empty input → empty output.
      expect(mysql.generate(const []), isEmpty);
      expect(pg.generate(const []), isEmpty);

      // Non-empty input → TODO scaffold. Use a resolved FunctionElement.
      final data = await _resolveFuncData();
      expect(mysql.generate([data]), contains('TODO(mysql)'));
      expect(pg.generate([data]), contains('TODO(postgres)'));
    });
  });
}

Future<SqlFuncData> _resolveFuncData() async {
  // Reuse the sqlite function builder path to obtain a real FunctionElement is
  // overkill; instead resolve a library and grab the element directly.
  late SqlFuncData data;
  await resolveSource(
    '''
library t;
void foo() {}
''',
    (resolver) async {
      final lib = await resolver.findLibraryByName('t');
      final fn = lib!.topLevelElements.whereType<FunctionElement>().firstWhere(
            (e) => e.name == 'foo',
          );
      data = SqlFuncData(element: fn, sqlName: 'FOO');
    },
  );
  return data;
}
