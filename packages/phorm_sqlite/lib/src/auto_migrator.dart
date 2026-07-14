import 'package:phorm/phorm.dart';

import 'database_adapter.dart';

// =======================================================
// AUTO MIGRATOR 🔄
// =======================================================

/// Additive, non-destructive schema synchronization for SQLite.
///
/// Compares the live database schema (via `PRAGMA table_info` /
/// `sqlite_master`) against the generated `CREATE TABLE` schema of each
/// registered [Table] and applies the safe difference:
///
/// - missing columns → `ALTER TABLE ... ADD COLUMN ...`
/// - missing indexes / triggers → created from the schema statements
///
/// Destructive or ambiguous changes (dropped columns, type changes, renames,
/// `NOT NULL` columns without a default, `UNIQUE`/`PRIMARY KEY` additions)
/// are **never** applied automatically — they are logged with a suggestion
/// to write an explicit [TableMigration].
///
/// Enabled via `DB(autoMigrate: true)`; runs on every database open, so no
/// manual version bump is required for purely additive model changes.
class AutoMigrator {
  /// Creates an auto-migrator that reports its actions to [logger].
  AutoMigrator({this.logger});

  /// Logger for applied statements and skipped-change warnings.
  final PhormLogger? logger;

  /// Extracts `column name → full column definition` from the single
  /// `CREATE TABLE` [statement] of a generated schema.
  ///
  /// Table-level clauses (`FOREIGN KEY ...`, `PRIMARY KEY (...)`,
  /// `UNIQUE (...)`, `CHECK (...)`, `CONSTRAINT ...`) are ignored.
  static Map<String, String> parseColumnDefinitions(String statement) {
    final defs = <String, String>{};
    final open = statement.indexOf('(');
    final close = statement.lastIndexOf(')');
    if (open == -1 || close <= open) return defs;

    final body = statement.substring(open + 1, close);
    for (final rawLine in _splitTopLevel(body)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final upper = line.toUpperCase();
      if (upper.startsWith('FOREIGN KEY') ||
          upper.startsWith('PRIMARY KEY') ||
          upper.startsWith('UNIQUE') ||
          upper.startsWith('CHECK') ||
          upper.startsWith('CONSTRAINT')) {
        continue;
      }

      final match = RegExp(r'^["`\[]?(\w+)["`\]]?\s').firstMatch(line);
      if (match == null) continue;
      defs[match.group(1)!] = line;
    }
    return defs;
  }

  /// Splits the body of a CREATE TABLE on commas that are not inside
  /// parentheses or quotes (so `CHECK(x IN ('a', 'b'))` stays intact).
  static List<String> _splitTopLevel(String body) {
    final parts = <String>[];
    final current = StringBuffer();
    var depth = 0;
    var inQuote = false;
    var quoteChar = '';

    for (var i = 0; i < body.length; i++) {
      final ch = body[i];
      if (inQuote) {
        if (ch == quoteChar) inQuote = false;
      } else if (ch == "'" || ch == '"') {
        inQuote = true;
        quoteChar = ch;
      } else if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
      } else if (ch == ',' && depth == 0) {
        parts.add(current.toString());
        current.clear();
        continue;
      }
      current.write(ch);
    }
    if (current.isNotEmpty) parts.add(current.toString());
    return parts;
  }

  /// Returns a human-readable reason when a column [definition] cannot be
  /// applied via `ALTER TABLE ... ADD COLUMN`, or `null` when it is safe.
  ///
  /// SQLite restrictions: no `PRIMARY KEY`/`UNIQUE` on added columns, and
  /// `NOT NULL` requires a non-null constant `DEFAULT`.
  static String? addColumnIssue(String definition) {
    final upper = definition.toUpperCase();
    if (upper.contains('PRIMARY KEY')) {
      return 'PRIMARY KEY columns cannot be added to an existing table';
    }
    if (upper.contains('UNIQUE')) {
      return 'UNIQUE columns cannot be added via ALTER TABLE';
    }
    final hasDefault = upper.contains('DEFAULT');
    if (upper.contains('NOT NULL') && !hasDefault) {
      return 'NOT NULL column without a DEFAULT cannot be added '
          'to a table that may contain rows';
    }
    return null;
  }

  /// Name of the object created by a `CREATE [UNIQUE] INDEX` /
  /// `CREATE TRIGGER` [statement], or `null` for other statements.
  static String? createdObjectName(String statement) {
    final match = RegExp(
      r'CREATE\s+(?:UNIQUE\s+)?(?:INDEX|TRIGGER)\s+(?:IF\s+NOT\s+EXISTS\s+)?["`\[]?(\w+)',
      caseSensitive: false,
    ).firstMatch(statement);
    return match?.group(1);
  }

  /// Synchronizes one existing [table] with its schema [statements]
  /// (as produced by splitting `table.schema`).
  ///
  /// Returns the list of SQL statements that were executed.
  Future<List<String>> syncTable(
    Database db,
    Table table,
    List<String> statements,
  ) async {
    final applied = <String>[];

    final createTable = statements.firstWhere(
      (s) => _isCreateTableFor(s, table.name),
      orElse: () => '',
    );

    // 1. Missing columns
    if (createTable.isNotEmpty) {
      final targetDefs = parseColumnDefinitions(createTable);
      final liveInfo = await db.rawQuery('PRAGMA table_info(${table.name})');
      final liveColumns = liveInfo.map((r) => r['name']! as String).toSet();

      for (final entry in targetDefs.entries) {
        if (liveColumns.contains(entry.key)) continue;

        final issue = addColumnIssue(entry.value);
        if (issue != null) {
          logger?.info(
            'autoMigrate ⚠️ skipped new column ${table.name}.${entry.key} — '
            '$issue. Write an explicit migration for it.',
          );
          continue;
        }

        final sql = 'ALTER TABLE ${table.name} ADD COLUMN ${entry.value}';
        logger?.info('autoMigrate: $sql');
        await db.execute(sql);
        applied.add(sql);
      }

      // Columns present in the database but absent from the model are left
      // untouched — dropping data automatically is never safe.
      final targetColumns = targetDefs.keys.toSet();
      for (final col in liveColumns.difference(targetColumns)) {
        logger?.info(
          'autoMigrate ⚠️ column ${table.name}.$col exists in the database but '
          'not in the model. Left as-is; drop it with an explicit migration '
          'if it is no longer needed.',
        );
      }
    }

    // 2. Missing indexes and triggers
    for (final statement in statements) {
      final name = createdObjectName(statement);
      if (name == null) continue;

      final exists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = ?",
        [name],
      );
      if (exists.isNotEmpty) continue;

      logger?.info('autoMigrate: creating missing schema object $name');
      await db.execute(statement);
      applied.add(statement);
    }

    return applied;
  }

  static bool _isCreateTableFor(String statement, String tableName) {
    final match = RegExp(
      r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["`\[]?(\w+)',
      caseSensitive: false,
    ).firstMatch(statement);
    return match?.group(1) == tableName;
  }
}
