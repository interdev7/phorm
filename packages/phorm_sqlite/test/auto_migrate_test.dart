import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';

/// Minimal model used to drive auto-migration scenarios.
class Note extends Model {
  Note({required this.id, required this.title, this.body});

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as int,
    title: json['title'] as String,
    body: json['body'] as String?,
  );

  final int id;
  final String title;
  final String? body;

  @override
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};
}

Table<Note> _notesTable({
  required String schema,
  required List<String> columns,
}) {
  return Table<Note>(
    name: 'notes',
    schema: schema,
    fromJson: Note.fromJson,
    type: Note,
    columns: columns,
    timestamps: false,
  );
}

const _schemaV1 = '''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL
);
''';

const _schemaV2 = '''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT,
  views INTEGER NOT NULL DEFAULT 0,
  secret TEXT NOT NULL,
  code TEXT UNIQUE
);

CREATE INDEX notes_title_idx ON notes(title);
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('phorm_auto_migrate_');
    await Directory(join(tempDir.path, 'databases')).create(recursive: true);
    for (final channel in [
      'plugins.flutter.io/path_provider',
      'plugins.flutter.io/path_provider_macos',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(channel),
            (call) async => tempDir.path,
          );
    }
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('AutoMigrator parsing', () {
    test('parseColumnDefinitions extracts one definition per column', () {
      final defs = AutoMigrator.parseColumnDefinitions('''
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  gender TEXT NOT NULL CONSTRAINT gender_check CHECK(gender IN ('M', 'F', 'Other')),
  is_active INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (team_id) REFERENCES teams (id)
)''');
      expect(defs.keys, ['id', 'gender', 'is_active']);
      // The comma inside CHECK(... IN ('M', 'F', ...)) must not split the def.
      expect(defs['gender'], contains("IN ('M', 'F', 'Other')"));
      expect(defs['is_active'], 'is_active INTEGER NOT NULL DEFAULT 1');
    });

    test('addColumnIssue flags SQLite ADD COLUMN restrictions', () {
      expect(AutoMigrator.addColumnIssue('x TEXT'), isNull);
      expect(
        AutoMigrator.addColumnIssue('x INTEGER NOT NULL DEFAULT 0'),
        isNull,
      );
      expect(AutoMigrator.addColumnIssue('x TEXT NOT NULL'), isNotNull);
      expect(AutoMigrator.addColumnIssue('x TEXT UNIQUE'), isNotNull);
      expect(AutoMigrator.addColumnIssue('x INTEGER PRIMARY KEY'), isNotNull);
    });

    test('createdObjectName recognizes indexes and triggers', () {
      expect(
        AutoMigrator.createdObjectName(
          'CREATE UNIQUE INDEX users_email_idx ON users(email)',
        ),
        'users_email_idx',
      );
      expect(
        AutoMigrator.createdObjectName(
          'CREATE TRIGGER update_users_timestamp AFTER UPDATE ON users '
          'FOR EACH ROW BEGIN UPDATE users SET updated_at = 1; END',
        ),
        'update_users_timestamp',
      );
      expect(
        AutoMigrator.createdObjectName('CREATE TABLE x (id INTEGER)'),
        isNull,
      );
    });
  });

  group('DB(autoMigrate: true)', () {
    test(
      'adds safe columns and indexes, preserves data, skips unsafe',
      () async {
        const dbName = 'auto_migrate_v1.db';

        // 1. Create the database with the v1 schema and insert a row.
        final dbV1 = DB(
          version: 1,
          databaseName: dbName,
          tables: [
            _notesTable(schema: _schemaV1, columns: ['id', 'title']),
          ],
          singleInstance: false,
          logger: null,
        );
        final rawV1 = await dbV1.database;
        await rawV1.insert('notes', {'title': 'first'});
        await dbV1.close();

        // 2. Reopen with the v2 schema (new columns + index), same version.
        final dbV2 = DB(
          version: 1,
          databaseName: dbName,
          tables: [
            _notesTable(
              schema: _schemaV2,
              columns: ['id', 'title', 'body', 'views', 'secret', 'code'],
            ),
          ],
          singleInstance: false,
          autoMigrate: true,
          logger: null,
        );
        final rawV2 = await dbV2.database;

        final info = await rawV2.rawQuery('PRAGMA table_info(notes)');
        final columns = info.map((r) => r['name']).toSet();
        // Safe additions applied:
        expect(columns, containsAll(['body', 'views']));
        // Unsafe additions skipped (NOT NULL without default, UNIQUE):
        expect(columns, isNot(contains('secret')));
        expect(columns, isNot(contains('code')));

        // Existing data preserved, new column has its default.
        final rows = await rawV2.rawQuery('SELECT * FROM notes');
        expect(rows, hasLength(1));
        expect(rows.first['title'], 'first');
        expect(rows.first['views'], 0);

        // Missing index created.
        final index = await rawV2.rawQuery(
          "SELECT name FROM sqlite_master WHERE name = 'notes_title_idx'",
        );
        expect(index, hasLength(1));
        await dbV2.close();
      },
    );

    test('creates a brand-new table without a version bump', () async {
      const dbName = 'auto_migrate_new_table.db';

      final dbV1 = DB(
        version: 1,
        databaseName: dbName,
        tables: const [],
        singleInstance: false,
        logger: null,
      );
      await dbV1.database;
      await dbV1.close();

      final dbV2 = DB(
        version: 1,
        databaseName: dbName,
        tables: [
          _notesTable(schema: _schemaV1, columns: ['id', 'title']),
        ],
        singleInstance: false,
        autoMigrate: true,
        logger: null,
      );
      final raw = await dbV2.database;
      final check = await raw.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='notes'",
      );
      expect(check, hasLength(1));
      await dbV2.close();
    });

    test('is idempotent: second open applies nothing new', () async {
      const dbName = 'auto_migrate_idempotent.db';

      DB make() => DB(
        version: 1,
        databaseName: dbName,
        tables: [
          _notesTable(
            schema: _schemaV2,
            columns: ['id', 'title', 'body', 'views', 'secret', 'code'],
          ),
        ],
        singleInstance: false,
        autoMigrate: true,
        logger: null,
      );

      final first = make();
      await first.database;
      await first.close();

      // Second open over the same file must not throw (duplicate column /
      // index errors would surface here if the diff were not idempotent).
      final second = make();
      final raw = await second.database;
      final rows = await raw.rawQuery('SELECT COUNT(*) AS c FROM notes');
      expect(rows.first['c'], 0);
      await second.close();
    });
  });
}
