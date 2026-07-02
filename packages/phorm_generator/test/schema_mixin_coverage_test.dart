import 'package:test/test.dart';

import 'gen_common.dart';

void main() {
  test('rich sqlite model exercises schema + mixin generation', () async {
    final out = await generateSchema(r'''
import 'dart:typed_data';
import 'package:phorm_annotations/phorm_annotations.dart';

enum Color { red, green }

class Nested {
  final int n;
  const Nested(this.n);
  Map<String, dynamic> toJson() => {'n': n};
  factory Nested.fromJson(Map<String, dynamic> j) => Nested(j['n'] as int);
}

class MsConverter extends ValueConverter<DateTime, int> {
  const MsConverter();
  @override
  DateTime fromSql(int v) => DateTime.fromMillisecondsSinceEpoch(v);
  @override
  int toSql(DateTime v) => v.millisecondsSinceEpoch;
}

class ContainsValidator implements ISqlValidator {
  final List<dynamic> values;
  const ContainsValidator(this.values);
  @override
  String? get constraint => null;
  // Computed getter — unreadable at generation time, forces the values fallback.
  @override
  String get sql {
    return values.map((v) => "'$v'").join(', ');
  }
}

class MyJsonValidator implements IJsonValidator {
  const MyJsonValidator();
  @override
  String? get constraint => 'json_c';
  @override
  bool isValid(dynamic value) => true;
}

@Schema(
  tableName: 'everything',
  paranoid: true,
  indexes: [
    Index(columns: ['name']),
    Index(columns: ['tag'], unique: true),
  ],
)
class Everything {
  @ID(autoIncrement: true)
  final int id;
  @Column()
  final String name;
  @Column(nullable: true)
  final String? nick;
  @Column(unique: true, defaultValue: 'x')
  final String tag;
  @Column(defaultValue: 5)
  final int count;
  @Column(defaultValue: 1.5)
  final double ratio;
  @Column(defaultValue: true)
  final bool active;
  @Column()
  final num amount;
  @Column()
  final DateTime when;
  @Column()
  final BigInt big;
  @Column()
  final Uri uri;
  @Column()
  final Duration dur;
  @Column()
  final Uint8List bytes;
  @Column()
  final Color color;
  @Column(nullable: true)
  final Color? optColor;
  @Column()
  final List<int> nums;
  @Column(nullable: true)
  final List<int>? optNums;
  @Column()
  final List<Nested> nestedList;
  @Column()
  final Set<String> tags;
  @Column()
  final Map<String, int> counts;
  @Column(nullable: true)
  final Map<String, Nested>? optMap;
  @Column()
  final Nested nested;
  @Column(nullable: true)
  final Nested? optNested;
  @Column(converter: MsConverter())
  final DateTime ms;
  @Column(nullable: true, converter: MsConverter())
  final DateTime? optMs;
  @Column(collate: 'NOCASE')
  final String cs;
  @Column(sqlType: 'JSON')
  final String rawJson;
  @Column(type: VARCHAR(100))
  final String vc;
  @Column(type: DECIMAL(10, 2))
  final double dec;
  @Column(type: TEXT())
  final String t2;
  @Column(type: JSON())
  final String j2;
  @Column(type: NUMERIC())
  final num num2;
  @Column(validators: [CustomSqlValidator('{column} > 0', constraint: 'pos_check')])
  final int checked;
  @Column(validators: [CustomSqlValidator('{column} <> 0')])
  final int anon;
  @Column(validators: [
    CustomSqlValidator('{column} > 1'),
    CustomSqlValidator('{column} < 9'),
  ])
  final int anon2;
  @Column(validators: [MyJsonValidator()])
  final String jv;
  @Column(validators: [ContainsValidator(['a', 'b'])])
  final String contains;

  const Everything(
    this.id,
    this.name,
    this.nick,
    this.tag,
    this.count,
    this.ratio,
    this.active,
    this.amount,
    this.when,
    this.big,
    this.uri,
    this.dur,
    this.bytes,
    this.color,
    this.optColor,
    this.nums,
    this.optNums,
    this.nestedList,
    this.tags,
    this.counts,
    this.optMap,
    this.nested,
    this.optNested,
    this.ms,
    this.optMs,
    this.cs,
    this.rawJson,
    this.vc,
    this.dec,
    this.t2,
    this.j2,
    this.num2,
    this.checked,
    this.anon,
    this.anon2,
    this.jv,
    this.contains,
  );
}
''');
    expect(out, contains('CREATE TABLE everything'));
    expect(out, contains('CONSTRAINT pos_check CHECK'));
    expect(out, contains('IN (')); // ContainsValidator fallback
    expect(out, contains(r'_$validateEverything')); // json validator method
    expect(out, contains('deleted_at')); // paranoid
    expect(out, contains('CREATE UNIQUE INDEX'));
  });

  test('relationships (class-level, type + string) and field-level', () async {
    final out = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'authors')
class Author {
  @ID()
  final int id;
  @Column()
  final String name;
  const Author(this.id, this.name);
}

class Comment {
  final int id;
  const Comment(this.id);
  Map<String, dynamic> toJson() => {'id': id};
  factory Comment.fromJson(Map<String, dynamic> j) => Comment(j['id'] as int);
}

class Tag {
  final int id;
  const Tag(this.id);
  Map<String, dynamic> toJson() => {'id': id};
  factory Tag.fromJson(Map<String, dynamic> j) => Tag(j['id'] as int);
}

class Profile {
  final int id;
  const Profile(this.id);
  Map<String, dynamic> toJson() => {'id': id};
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(j['id'] as int);
}

@Schema(
  tableName: 'posts',
  relationships: [
    BelongsTo(model: Author, foreignKey: 'author_id'),
    HasMany(model: 'comments', foreignKey: 'post_id'),
    HasOne(model: 'profile', foreignKey: 'post_id'),
    ManyToMany(
      model: 'categories',
      pivotTable: 'post_categories',
      foreignKey: 'post_id',
      relatedKey: 'category_id',
      createPivot: true,
      pivotForeignKeys: true,
    ),
    Join(model: 'joined', foreignKey: 'j_id', onDelete: 'CASCADE', onUpdate: 'SET NULL'),
  ],
)
class Post {
  @ID()
  final int id;
  @Column()
  final String title;
  const Post(this.id, this.title);
}

@Schema(tableName: 'field_rels')
class FieldRels {
  @ID()
  final int id;
  @BelongsTo(model: Author, foreignKey: 'author_id')
  final String author;
  @HasMany(model: 'comments', foreignKey: 'rel_id')
  final List<Comment> comments;
  @HasOne(model: 'profile', foreignKey: 'rel_id')
  final Profile profile;
  @ManyToMany(model: 'tags', pivotTable: 'rel_tags', foreignKey: 'rel_id', relatedKey: 'tag_id')
  final List<Tag> tags;
  @Join(model: 'joined', foreignKey: 'j2_id')
  final String j;
  const FieldRels(this.id, this.author, this.comments, this.profile, this.tags, this.j);
}
''');
    expect(out, contains('CREATE TABLE posts'));
    expect(out, contains('FOREIGN KEY'));
    expect(out, contains('CREATE TABLE IF NOT EXISTS post_categories'));
    expect(out, contains('includeComments')); // query relations extension
  });

  test(
    'toggles off (no toJson/fromJson/copyWith/toString/service), no timestamps',
    () async {
      final out = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(
  tableName: 'toggles',
  timestamps: false,
  useToJson: false,
  useFromJson: false,
  useCopyWith: false,
  useToString: false,
  generateFullService: false,
)
class Toggles {
  @ID()
  final String id;
  @Column()
  final String name;
  const Toggles(this.id, this.name);
}
''');
      expect(out, contains('CREATE TABLE toggles'));
      expect(out, isNot(contains('copyWith')));
      expect(out, isNot(contains('class Toggles {'))); // no service class
    },
  );

  test('pascalCase and camelCase naming strategies', () async {
    final pascal = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'p', columnNaming: ColumnNamingStrategy.pascalCase)
class Pascal {
  @ID()
  final String id;
  @Column()
  final String firstName;
  const Pascal(this.id, this.firstName);
}
''');
    expect(pascal, contains('FirstName'));

    final camel = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'c', columnNaming: ColumnNamingStrategy.camelCase)
class Camel {
  @ID()
  final String id;
  @Column()
  final String firstName;
  const Camel(this.id, this.firstName);
}
''');
    expect(camel, contains('firstName'));
  });

  test('generic model exercises type-parameter paths', () async {
    final out = await generateSchema('''
import 'package:phorm_annotations/phorm_annotations.dart';

@Schema(tableName: 'boxes')
class Box<T> {
  @ID()
  final String id;
  @Column()
  final T value;
  @Column(nullable: true)
  final T? optValue;
  @Column()
  final List<T> items;
  const Box(this.id, this.value, this.optValue, this.items);
}
''');
    expect(out, contains('CREATE TABLE boxes'));
    expect(out, contains('toJsonT'));
  });
}
