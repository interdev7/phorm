import 'package:build/build.dart';
import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:phorm_generator/builder.dart';
import 'package:phorm_generator/src/generators/schema_generator.dart';
import 'package:test/test.dart';

import 'gen_common.dart';

void main() {
  test(
    'converter S-types, nullable scalars, json validator args, unbacked param',
    () async {
      final out = await generateSchema(r'''
import 'dart:typed_data';
import 'package:phorm_annotations/phorm_annotations.dart';

class Nested {
  final int n;
  const Nested(this.n);
  Map<String, dynamic> toJson() => {'n': n};
  factory Nested.fromJson(Map<String, dynamic> j) => Nested(j['n'] as int);
}

class DblConv extends ValueConverter<String, double> {
  const DblConv();
  @override
  String fromSql(double v) => '$v';
  @override
  double toSql(String v) => 0;
}

class BoolConv extends ValueConverter<String, bool> {
  const BoolConv();
  @override
  String fromSql(bool v) => '$v';
  @override
  bool toSql(String v) => false;
}

class StrConv extends ValueConverter<int, String> {
  const StrConv();
  @override
  int fromSql(String v) => 0;
  @override
  String toSql(int v) => '$v';
}

class NumConv extends ValueConverter<String, num> {
  const NumConv();
  @override
  String fromSql(num v) => '$v';
  @override
  num toSql(String v) => 0;
}

class BytesConv extends ValueConverter<String, Uint8List> {
  const BytesConv();
  @override
  String fromSql(Uint8List v) => '';
  @override
  Uint8List toSql(String v) => Uint8List(0);
}

class RangeJson implements IJsonValidator {
  final int min;
  final String label;
  final List<int> allowed;
  final IJsonValidator? inner;
  const RangeJson(this.min, {this.label = 'x', this.allowed = const [1, 2], this.inner});
  @override
  String? get constraint => 'range_c';
  @override
  bool isValid(dynamic value) => true;
}

class MyJsonValidator implements IJsonValidator {
  const MyJsonValidator();
  @override
  String? get constraint => null;
  @override
  bool isValid(dynamic value) => true;
}

class ContainsValidator implements ISqlValidator {
  final List<dynamic> values;
  const ContainsValidator(this.values);
  @override
  String? get constraint => null;
  @override
  String get sql {
    return values.join(',');
  }
}

@Schema(tableName: 'targeted')
class Targeted {
  @ID()
  final String id;

  @Column(converter: DblConv())
  final String cDbl;
  @Column(converter: BoolConv())
  final String cBool;
  @Column(converter: StrConv())
  final int cStr;
  @Column(converter: NumConv())
  final String cNum;
  @Column(converter: BytesConv())
  final String cBytes;

  // Nullable scalars without converters (fromJson nullable branches).
  @Column(nullable: true)
  final DateTime? dt2;
  @Column(nullable: true)
  final BigInt? big2;
  @Column(nullable: true)
  final Uri? uri2;
  @Column(nullable: true)
  final Duration? dur2;
  @Column(nullable: true)
  final bool? flag2;
  @Column(nullable: true)
  final Set<String>? set2;
  // Nullable list of a non-passthrough type (toJson nullable map branch).
  @Column(nullable: true)
  final List<Nested>? optNestedList;

  // JSON validator with positional + named + list + nested args.
  @Column(validators: [RangeJson(5, label: 'hi', allowed: [1, 2], inner: MyJsonValidator())])
  final int ranged;

  // ISqlValidator values fallback with int, double, and a non-scalar → NULL.
  @Column(validators: [ContainsValidator([1, 2.5, true])])
  final int cont2;

  // Unbacked constructor parameter (not a field) → fromJson null branch.
  const Targeted(
    this.id,
    this.cDbl,
    this.cBool,
    this.cStr,
    this.cNum,
    this.cBytes,
    this.dt2,
    this.big2,
    this.uri2,
    this.dur2,
    this.flag2,
    this.set2,
    this.optNestedList,
    this.ranged,
    this.cont2,
    int ignored,
  );
}
''');
      expect(out, contains('CREATE TABLE targeted'));
      expect(out, contains('RangeJson(5')); // revived json validator with args
      expect(out, contains('ignored: null')); // unbacked constructor param
      expect(
        out,
        contains('IN (1, 2.5, NULL)'),
      ); // values fallback int/double/NULL
    },
  );

  test(
    'model without tableName + Type relationship to a tableName-less class',
    () async {
      final out = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema()
class Plain {
  @ID()
  final int id;
  @Column()
  final String name;
  const Plain(this.id, this.name);
}

@Schema(
  relationships: [BelongsTo(model: Plain, foreignKey: 'plain_id')],
)
class Owner {
  @ID()
  final int id;
  const Owner(this.id);
}
''');
      // Table name derived from the class name (camelToSnake).
      expect(out, contains('CREATE TABLE plain'));
      expect(out, contains('CREATE TABLE owner'));
    },
  );

  test(
    'field-level BelongsTo on int field + collection field needing plural',
    () async {
      final out = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'authors2')
class Author2 {
  @ID()
  final int id;
  const Author2(this.id);
}

class Comment2 {
  final int id;
  const Comment2(this.id);
  Map<String, dynamic> toJson() => {'id': id};
  factory Comment2.fromJson(Map<String, dynamic> j) => Comment2(j['id'] as int);
}

@Schema(tableName: 'fr2')
class FieldRels2 {
  @ID()
  final int id;
  @BelongsTo(model: Author2, foreignKey: 'author_id')
  final int authorRef;
  @HasMany(model: 'comment2', foreignKey: 'x_id')
  final List<Comment2> commentList;
  const FieldRels2(this.id, this.authorRef, this.commentList);
}
''');
      expect(out, contains('CREATE TABLE fr2'));
    },
  );

  test('BelongsTo on a dynamic field + JSON validator with a constraint field',
      () async {
    final out = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'authors3')
class Author3 {
  @ID()
  final int id;
  const Author3(this.id);
}

class NamedJson implements IJsonValidator {
  @override
  final String? constraint;
  const NamedJson({this.constraint});
  @override
  bool isValid(dynamic value) => true;
}

@Schema(tableName: 'dyn_rel')
class DynRel {
  @ID()
  final int id;
  @BelongsTo(model: Author3, foreignKey: 'author_id')
  final dynamic ref;
  @Column(validators: [NamedJson(constraint: 'named_c')])
  final String checked;
  const DynRel(this.id, this.ref, this.checked);
}
''');
    expect(out, contains('CREATE TABLE dyn_rel'));
    expect(out, contains("constraint: 'named_c'"));
  });

  group('unused dialect helpers (direct)', () {
    test('quoteIdentifier is a no-op for every dialect', () {
      for (final kind in SqlDialectKind.values) {
        final g = SchemaGenerator.fromKind(kind);
        expect(g.quoteIdentifier('col'), 'col');
      }
    });
  });

  test('sqlSchemaBuilder factory builds a SharedPartBuilder', () {
    final builder = sqlSchemaBuilder(BuilderOptions.empty);
    expect(builder, isNotNull);
  });
}
