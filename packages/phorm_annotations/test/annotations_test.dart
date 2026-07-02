import 'package:phorm_annotations/phorm_annotations.dart';
import 'package:test/test.dart';

/// Minimal concrete model for table/migration tests.
class _User extends Model {
  _User(this.id);
  final int id;
  @override
  Map<String, dynamic> toJson() => {'id': id};
}

/// Concrete factory for [Factory] coverage.
class _UserFactory extends Factory<_User> {
  int _seq = 0;
  @override
  _User create() => _User(_seq++);
}

/// Concrete value converter for coverage.
class _DateConverter extends ValueConverter<DateTime, int> {
  const _DateConverter();
  @override
  DateTime fromSql(int sqlValue) =>
      DateTime.fromMillisecondsSinceEpoch(sqlValue);
  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

/// Concrete JSON validator for coverage.
class _NotEmptyValidator implements IJsonValidator {
  const _NotEmptyValidator();
  @override
  String? get constraint => 'not_empty';
  @override
  bool isValid(dynamic value) => value != null && '$value'.isNotEmpty;
}

/// Fake executor that records every executed statement.
class _FakeExecutor implements PhormDatabaseExecutor {
  final List<String> executed = [];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executed.add(sql);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      Future.value(0);

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    String? conflictAlgorithm,
  }) =>
      Future.value(0);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) =>
      Future.value([]);

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      Future.value(0);
}

Table<_User> _table({String schema = 'CREATE TABLE users (id INTEGER)'}) =>
    Table<_User>(
      schema: schema,
      name: 'users',
      type: _User,
      fromJson: (m) => _User(m['id'] as int),
      columns: const ['id'],
    );

/// Concrete subclasses that `extends` the abstract validator interfaces so
/// their (const) super constructors are executed at runtime.
class _Validator extends IValidator {
  @override
  String? get constraint => null;
}

class _JsonValidator extends IJsonValidator {
  @override
  String? get constraint => null;
  @override
  bool isValid(dynamic value) => true;
}

class _SqlValidator extends ISqlValidator {
  @override
  String? get constraint => null;
  @override
  String get sql => '{column} IS NOT NULL';
}

void main() {
  group('PhormColumn', () {
    test('toString without table name returns plain name', () {
      expect(const PhormColumn<int>('id').toString(), 'id');
    });

    test('toString with table name returns qualified name', () {
      expect(
        const PhormColumn<int>('id', tableName: 'users').toString(),
        'users.id',
      );
    });
  });

  group('PhormColumn extension operators', () {
    const col = PhormColumn<int>('age');

    PhormCondition c(PhormCondition cond) => cond;

    test('comparison operators map to correct operator strings', () {
      expect(c(col.eq(1)).operator, '=');
      expect(c(col.ne(1)).operator, '!=');
      expect(c(col.gt(1)).operator, '>');
      expect(c(col.gte(1)).operator, '>=');
      expect(c(col.lt(1)).operator, '<');
      expect(c(col.lte(1)).operator, '<=');
    });

    test('like family operators', () {
      const s = PhormColumn<String>('name');
      expect(s.like('a%').operator, 'LIKE');
      expect(s.notLike('a%').operator, 'NOT LIKE');
      expect(s.ilike('a%').operator, 'ILIKE');
      expect(s.notIlike('a%').operator, 'NOT ILIKE');
      expect(s.regexp('a').operator, 'REGEXP');
      expect(s.startsWith('a').operator, 'STARTS WITH');
      expect(s.endsWith('a').operator, 'ENDS WITH');
    });

    test('list/range operators carry the values', () {
      expect(col.inList([1, 2]).value, [1, 2]);
      expect(col.notInList([1, 2]).operator, 'NOT IN');
      expect(col.between(1, 5).value, [1, 5]);
      expect(col.notBetween(1, 5).operator, 'NOT BETWEEN');
    });

    test('null / boolean operators', () {
      expect(col.isNull().operator, 'IS NULL');
      expect(col.isNotNull().operator, 'IS NOT NULL');
      expect(col.isTrue().operator, 'TRUE');
      expect(col.isFalse().operator, 'FALSE');
    });

    test('length operators', () {
      const s = PhormColumn<String>('name');
      expect(s.lengthEq(3).operator, 'LENGTH =');
      expect(s.lengthNe(3).operator, 'LENGTH !=');
      expect(s.lengthGt(3).operator, 'LENGTH >');
      expect(s.lengthGte(3).operator, 'LENGTH >=');
      expect(s.lengthLt(3).operator, 'LENGTH <');
      expect(s.lengthLte(3).operator, 'LENGTH <=');
    });

    test('substr operators', () {
      const s = PhormColumn<String>('name');
      expect(s.substrEq(1, 2, 'ab').value, [1, 2, 'ab']);
      expect(s.substrLike(1, 2, 'a%').operator, 'SUBSTR LIKE');
      expect(s.substrIlike(1, 2, 'a%').operator, 'SUBSTR ILIKE');
    });

    test('date/time operators', () {
      const d = PhormColumn<DateTime>('created_at');
      final now = DateTime(2024);
      expect(d.dateOnlyEq(now).operator, 'DATE =');
      expect(d.dateOnlyGt(now).operator, 'DATE >');
      expect(d.dateOnlyLt(now).operator, 'DATE <');
      expect(d.dateOnlyBetween(now, now).value, [now, now]);
      expect(d.timeOnlyEq(now).operator, 'TIME =');
    });
  });

  group('NoEscapeDialect / ParamIndex', () {
    const dialect = NoEscapeDialect();

    test('ParamIndex starts at 1', () {
      expect(ParamIndex().value, 1);
    });

    test('escapeIdentifier returns the name unchanged', () {
      expect(dialect.escapeIdentifier('users.id'), 'users.id');
    });

    test('compilePlaceholder is always ?', () {
      expect(dialect.compilePlaceholder(3), '?');
    });

    test('compileJsonObject handles empty and non-empty maps', () {
      expect(dialect.compileJsonObject({}), 'json_object()');
      expect(
        dialect.compileJsonObject({'id': 'users.id', 'n': 'users.name'}),
        "json_object('id', users.id, 'n', users.name)",
      );
    });

    test('compileJsonArray wraps the expression', () {
      expect(
        dialect.compileJsonArray('obj', 'FROM users'),
        '(SELECT json_group_array(obj) FROM users)',
      );
    });
  });

  group('Exceptions', () {
    test('CHECK exception toString with and without constraint', () {
      expect(
        PhormCHECKValidatorException(
          table: 't',
          column: 'c',
          message: 'bad',
        ).toString(),
        'PhormCHECKValidatorException: [t.c] bad',
      );
      expect(
        PhormCHECKValidatorException(
          table: 't',
          column: 'c',
          message: 'bad',
          constraint: 'chk',
        ).toString(),
        contains('(Constraint: chk)'),
      );
    });

    test('JSON exception toString with and without constraint', () {
      expect(
        PhormJSONValidatorException(table: 't', column: 'c', message: 'bad')
            .toString(),
        'PhormJSONValidatorException: [t.c] bad',
      );
      expect(
        PhormJSONValidatorException(
          table: 't',
          column: 'c',
          message: 'bad',
          constraint: 'j',
        ).toString(),
        contains('(Constraint: j)'),
      );
    });
  });

  test('ReferentialAction exposes SQL action constants', () {
    expect(ReferentialAction.cascade, 'CASCADE');
    expect(ReferentialAction.setNull, 'SET NULL');
    expect(ReferentialAction.setDefault, 'SET DEFAULT');
    expect(ReferentialAction.restrict, 'RESTRICT');
    expect(ReferentialAction.noAction, 'NO ACTION');
  });

  group('Result data', () {
    test('Result holds data', () {
      expect(Result<int>(data: [1, 2]).data, [1, 2]);
    });
    test('ResultWithCount holds data and count', () {
      final r = ResultWithCount<int>(data: [1], count: 10);
      expect(r.data, [1]);
      expect(r.count, 10);
    });
  });

  test('Model default toJson is empty', () {
    expect(Model().toJson(), <String, dynamic>{});
  });

  group('Factory', () {
    test('createMany generates the requested number of models', () {
      final list = _UserFactory().createMany(3);
      expect(list, hasLength(3));
      expect(list.map((u) => u.id), [0, 1, 2]);
    });
  });

  group('SqlType hierarchy', () {
    test('parameterized types keep their arguments', () {
      expect(const VARCHAR(255).length, 255);
      expect(const DECIMAL(10, 2).precision, 10);
      expect(const DECIMAL(10, 2).scale, 2);
    });

    test('simple types are SqlType instances', () {
      final types = <SqlType>[
        const TEXT(),
        const INTEGER(),
        const BIGINT(),
        const BOOLEAN(),
        const REAL(),
        const DOUBLE(),
        const DATE(),
        const TIME(),
        const TIMESTAMP(),
        const JSON(),
        const JSONB(),
        const BLOB(),
      ];
      expect(types, everyElement(isA<SqlType>()));
      expect(types, hasLength(12));
    });

    test('legacy SqlTypes and Collate constants', () {
      expect(SqlTypes.text, 'TEXT');
      expect(SqlTypes.integer, 'INTEGER');
      expect(SqlTypes.real, 'REAL');
      expect(SqlTypes.blob, 'BLOB');
      expect(SqlTypes.numeric, 'NUMERIC');
      expect(Collate.binary, 'BINARY');
      expect(Collate.noCase, 'NOCASE');
      expect(Collate.rtrim, 'RTRIM');
    });
  });

  group('ValueConverter', () {
    const converter = _DateConverter();
    test('round-trips through SQL representation', () {
      final dt = DateTime.fromMillisecondsSinceEpoch(1000);
      expect(converter.toSql(dt), 1000);
      expect(converter.fromSql(1000), dt);
    });
  });

  group('Validators', () {
    test('CustomSqlValidator keeps sql and constraint', () {
      const v = CustomSqlValidator('{column} > 0', constraint: 'positive');
      expect(v.sql, '{column} > 0');
      expect(v.constraint, 'positive');
    });

    test('IJsonValidator implementation validates values', () {
      const v = _NotEmptyValidator();
      expect(v.constraint, 'not_empty');
      expect(v.isValid('x'), isTrue);
      expect(v.isValid(''), isFalse);
      expect(v.isValid(null), isFalse);
    });
  });

  group('Column annotations', () {
    test('Column stores its options', () {
      const c = Column(
        columnName: 'full_name',
        type: VARCHAR(120),
        unique: true,
        defaultValue: 'x',
        collate: Collate.noCase,
      );
      expect(c.columnName, 'full_name');
      expect(c.unique, isTrue);
      expect(c.defaultValue, 'x');
      expect(c.collate, 'NOCASE');
      expect(c.type, isA<VARCHAR>());
    });

    test('ID defaults to unique and not auto-increment', () {
      const id = ID();
      expect(id.unique, isTrue);
      expect(id.autoIncrement, isFalse);
      expect(const ID(autoIncrement: true).autoIncrement, isTrue);
    });

    test('Schema defaults', () {
      const s = Schema();
      expect(s.columnNaming, ColumnNamingStrategy.snakeCase);
      expect(s.paranoid, isFalse);
      expect(s.timestamps, isTrue);
      expect(s.useToJson, isTrue);
      expect(s.useFromJson, isTrue);
      expect(s.useCopyWith, isTrue);
      expect(s.useToString, isTrue);
      expect(s.useValidator, isTrue);
      expect(s.indexes, isEmpty);
      expect(s.relationships, isEmpty);
    });

    test('ColumnNamingStrategy has the three strategies', () {
      expect(ColumnNamingStrategy.values, hasLength(3));
    });

    test('SqlFunc stores optional name', () {
      expect(const SqlFunc().name, isNull);
      expect(const SqlFunc(name: 'UPPER').name, 'UPPER');
    });

    test('Index stores columns and uniqueness', () {
      const i = Index(columns: ['a', 'b'], unique: true);
      expect(i.columns, ['a', 'b']);
      expect(i.unique, isTrue);
    });
  });

  group('Relationships', () {
    test('isCollection flag per relationship type', () {
      expect(
        const HasMany(model: 'posts', foreignKey: 'user_id').isCollection,
        isTrue,
      );
      expect(
        const HasOne(model: 'profile', foreignKey: 'user_id').isCollection,
        isFalse,
      );
      expect(
        const BelongsTo(model: 'user', foreignKey: 'user_id').isCollection,
        isFalse,
      );
      expect(
        const Join(model: 'user', foreignKey: 'user_id').isCollection,
        isFalse,
      );
      expect(
        const ManyToMany(
          model: 'roles',
          pivotTable: 'user_roles',
          foreignKey: 'user_id',
          relatedKey: 'role_id',
        ).isCollection,
        isTrue,
      );
    });

    test('ManyToMany keeps pivot metadata', () {
      const m = ManyToMany(
        model: 'roles',
        pivotTable: 'user_roles',
        foreignKey: 'user_id',
        relatedKey: 'role_id',
      );
      expect(m.pivotTable, 'user_roles');
      expect(m.relatedKey, 'role_id');
      expect(m.relatedLocalKey, 'id');
    });
  });

  group('Includable', () {
    test('table() resolves to the explicit name', () {
      final inc = Includable.table('posts');
      expect(inc.getTableName(const []), 'posts');
      expect(inc.attributes, isNull);
      expect(inc.include, isNull);
    });

    test('model() resolves via registered tables', () {
      final inc = Includable.model<_User>();
      expect(inc.getTableName([_table()]), 'users');
    });

    test('model() throws when type is not registered', () {
      final inc = Includable.model<_User>();
      expect(() => inc.getTableName(const []), throwsArgumentError);
    });
  });

  group('Attributes', () {
    test('include keeps only listed columns', () {
      expect(
        Attributes.include(['a', 'b']).apply(['a', 'b', 'c']),
        ['a', 'b'],
      );
    });

    test('exclude removes listed columns', () {
      expect(
        Attributes.exclude(['b']).apply(['a', 'b', 'c']),
        ['a', 'c'],
      );
    });
  });

  group('Table', () {
    test('auto-increment detected from schema', () {
      expect(
        _table(schema: 'CREATE TABLE users (id INTEGER AUTOINCREMENT)')
            .autoIncrement,
        isTrue,
      );
      expect(_table().autoIncrement, isFalse);
    });

    test('explicit autoIncrement overrides detection', () {
      final t = Table<_User>(
        schema: 'CREATE TABLE users (id INTEGER)',
        name: 'users',
        type: _User,
        fromJson: (m) => _User(0),
        autoIncrement: true,
      );
      expect(t.autoIncrement, isTrue);
    });

    test('detectSoftDelete looks for deleted_at column', () {
      expect(
        Table.detectSoftDelete('CREATE TABLE t (deleted_at TEXT)'),
        isTrue,
      );
      expect(Table.detectSoftDelete('CREATE TABLE t (id INT)'), isFalse);
    });

    test('fromJson maps a row to the model', () {
      expect(_table().fromJson({'id': 7}).id, 7);
    });

    test('migrate() returns a MigrationBuilder', () {
      expect(_table().migrate(), isA<MigrationBuilder<_User>>());
    });
  });

  group('MigrationBuilder', () {
    test('build aggregates raw / addColumn / rename / index migrations',
        () async {
      final table = _table()
          .migrate()
          .raw('SELECT 1', version: 2)
          .raw('SELECT ${'x' * 80}', version: 2) // exercises _truncate
          .addColumn(name: 'age', type: 'INTEGER', version: 2)
          .addColumn(
            name: 'email',
            type: 'TEXT',
            version: 2,
            nullable: false,
            defaultValue: "''",
          )
          .renameColumn(oldName: 'a', newName: 'b', version: 2)
          .createIndex(name: 'idx', columns: ['email'], version: 3)
          .createIndex(
            name: 'uidx',
            columns: ['email'],
            version: 3,
            unique: true,
          )
          .dropIndex(name: 'idx', version: 4)
          .build();

      expect(table.migrations, isNotEmpty);
      expect(table.name, 'users');

      // Execute every raw migration against a fake executor.
      final db = _FakeExecutor();
      for (final m in table.migrations) {
        await m.migrate(db, table);
      }
      expect(db.executed, contains('SELECT 1'));
      expect(
        db.executed.any((s) => s.contains('ADD COLUMN age')),
        isTrue,
      );
      expect(
        db.executed.any((s) => s.contains('NOT NULL DEFAULT')),
        isTrue,
      );
      expect(
        db.executed.any((s) => s.startsWith('CREATE UNIQUE INDEX')),
        isTrue,
      );
      expect(
        db.executed.any((s) => s.startsWith('DROP INDEX IF EXISTS')),
        isTrue,
      );
    });

    test('custom migration runs the provided callback', () async {
      var ran = false;
      final table = _table().migrate().custom(
        description: 'noop',
        version: 2,
        migrate: (db, t) async => ran = true,
      ).build();
      await table.migrations.single.migrate(_FakeExecutor(), table);
      expect(ran, isTrue);
    });

    test('addForeignKey and addCheckConstraint produce informational migrations',
        () async {
      final table = _table()
          .migrate()
          .addForeignKey(
            column: 'user_id',
            referenceTable: 'users',
            referenceColumn: 'id',
            version: 2,
          )
          .addCheckConstraint(constraint: 'age > 0', version: 2)
          .build();
      final db = _FakeExecutor();
      for (final m in table.migrations) {
        await m.migrate(db, table);
      }
      // Informational migrations don't execute SQL.
      expect(db.executed, isEmpty);
    });

    test('dropColumn migration throws UnsupportedError when executed', () async {
      final table =
          _table().migrate().dropColumn(name: 'age', version: 2).build();
      await expectLater(
        table.migrations.single.migrate(_FakeExecutor(), table),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('build preserves columns, timestamps and autoIncrement', () {
      final source = Table<_User>(
        schema: 'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT)',
        name: 'users',
        type: _User,
        fromJson: (m) => _User(m['id'] as int),
        columns: const ['id', 'name', 'email'],
        timestamps: false,
        paranoid: true,
      );

      final rebuilt =
          source.migrate().addColumn(name: 'age', type: 'INTEGER', version: 2).build();

      // These fields used to be dropped by build(), causing broken
      // relationship serialization and unwanted timestamp injection.
      expect(rebuilt.columns, source.columns);
      expect(rebuilt.timestamps, isFalse);
      expect(rebuilt.autoIncrement, isTrue);
      // Other carried-over fields stay intact too.
      expect(rebuilt.paranoid, isTrue);
      expect(rebuilt.primaryKey, 'id');
      expect(rebuilt.schema, source.schema);
    });
  });

  group('PhormConsoleLogger', () {
    test('logs all levels without throwing (colors enabled)', () {
      const PhormConsoleLogger()
        ..info('hello')
        ..query('SELECT 1', ['a'], const Duration(milliseconds: 2))
        ..query('SELECT 1', null, const Duration(milliseconds: 2))
        ..slowQuery('SELECT 1', ['a'], const Duration(seconds: 1))
        ..slowQuery('SELECT 1', [], const Duration(seconds: 1))
        ..error('boom', Exception('x'), StackTrace.current)
        ..error('boom');
    });

    test('logs all levels without throwing (colors disabled)', () {
      const PhormConsoleLogger(enableColors: false)
        ..info('hello')
        ..query('SELECT 1', ['a'], const Duration(milliseconds: 2))
        ..slowQuery('SELECT 1', ['a'], const Duration(seconds: 1))
        ..error('boom', 'details');
    });
  });

  group('validator interface constructors', () {
    test('concrete subclasses run the abstract super constructors', () {
      // Runtime (non-const) invocation executes each super constructor.
      expect(_Validator().constraint, isNull);
      expect(_JsonValidator().isValid('x'), isTrue);
      expect(_SqlValidator().sql, contains('{column}'));
    });
  });

  group('SQLite affinity types', () {
    test('NUMERIC affinity type is constructible', () {
      // Runtime (non-const) construction so the constructor is covered.
      // ignore: prefer_const_constructors
      final SqlType t = NUMERIC();
      expect(t, isA<NUMERIC>());
    });
  });
}
