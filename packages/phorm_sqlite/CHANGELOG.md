# Changelog

## [1.10.2]

- **Fix `Unsupported operation: Platform._operatingSystem` on Flutter Web.**
  `DB` touched `dart:io` (`Platform` in `getDatabasesPath`, `File` in
  downgrade/reset/version checks) on every open; on web those are stubs that
  throw at runtime. All filesystem/platform code is now guarded with
  `kIsWeb`: the database name is passed straight to the IndexedDB-backed
  store, and file cleanup steps are skipped on web.
- **Fix `SqliteException(14)` on desktop first launch.** The default
  database location (`.../Application Support/<app>/databases/`) was never
  created; SQLite does not create intermediate directories, so opening the
  database failed on a fresh install (macOS/Windows/Linux). The parent
  directory is now created before opening.

## [1.10.1]

- **Fix Flutter Web builds.** `database_adapter.dart` imported
  `package:sqlite3/sqlite3.dart` (the FFI entry point) for `SqliteException`,
  which pulled `dart:ffi` into web compilations and failed them. It now
  imports the web-safe `package:sqlite3/common.dart`.

## [1.10.0]

- `Database` and `Transaction` implement the new `ColumnarQueryExecutor`
  capability from `phorm ^1.9.0`: SELECT results cross the isolate boundary
  in columnar form end-to-end, enabling the core's faster model-read path.
  The `DatabaseIsolate` backend interface gains `queryColumnar` (native
  returns the isolate's packed result directly; web adapts its map-based
  results).

## [1.9.0]

- **Bulk operation performance** (5k-row insert: ~41ms → ~7ms on an Apple M3):
  - batches of same-shape inserts are coalesced into a columnar
    `BatchInsertMany` — column names cross the isolate boundary once and the
    isolate reuses a single prepared statement for all rows;
  - table-change notifications from the SQLite update hook are buffered
    during batches/transactions and flushed once per distinct table after
    COMMIT, instead of one cross-isolate message per affected row;
  - SELECT results use a columnar transfer (column names once + value
    lists) instead of one map per row, with maps rebuilt caller-side sharing
    key instances.
- Reactive `watch*`/`changeStream` semantics are unchanged: listeners still
  receive one event per modified table after commit.

## [1.8.0]

- **Batch operations are ~11× faster.** `Batch.commit()` now sends plain
  insert/update/delete batches to the database isolate as a **single
  message** executed there in one transaction, instead of one isolate
  round-trip per operation (5000 inserts: ~457ms → ~41ms on an Apple M3).
  Falls back to the previous per-operation path when results are requested
  (`noResult: false`), `continueOnError` is set, raw SQL is batched, a
  non-REPLACE conflict algorithm is used, or an outer transaction is active.
- **`DB(onQuery: ...)` query observer** — a callback invoked for every
  database operation, independently of `logQueries`: successful, slow
  (per `slowQueryThreshold`) and failed ones (with error and stack trace).
  Feed it to metrics, tracing or crash reporting. Requires `phorm ^1.8.0`.

## [1.7.0]

- **Nested transactions via SQLite savepoints.** `transaction()` can now be
  called inside another transaction: the outermost call issues
  `BEGIN`/`COMMIT` as before, inner calls create a `SAVEPOINT` that is
  released on success or rolled back on failure. A failed inner transaction
  undoes only its own writes and does not poison the outer one; an outer
  rollback still reverts everything. Previously a nested call failed with
  "cannot start a transaction within a transaction".

## [1.6.1]

- Bumped bundled `phorm` core to `^1.5.0`, bringing typed condition
  composition with the `&` / `|` operators
  (`age.gt(18) & (city.eq('Sofia') | city.eq('Plovdiv'))`).
- `phorm_generator` stays pinned `<1.4.0`: generator 1.4.x needs
  `analyzer ^13` (`meta ^1.18.3`), which conflicts with the `meta` version
  pinned by `flutter_test` on the current Flutter stable.

## [1.6.0]

- **New: automatic additive migrations** — `DB(autoMigrate: true)` (also on
  `DB.autoVersion`). On every open, each registered table's live schema is
  compared with its generated `CREATE TABLE` schema; missing tables, columns,
  indexes and triggers are created automatically — no version bump needed for
  additive model changes. Destructive or ambiguous changes (dropped/renamed
  columns, type changes, `NOT NULL` without a `DEFAULT`, `UNIQUE`/
  `PRIMARY KEY` additions) are never applied: they are logged with a
  suggestion to write an explicit `TableMigration`. Off by default; explicit
  migrations keep working alongside and remain the tool for data transforms.
- Re-enabled most `very_good_analysis` lints for `lib/` (generated `*.g.dart`
  files are excluded from analysis). Internal cleanups with no behavior
  changes: `on Object` catch clauses, removed unnecessary awaits, single
  `changeStream` tear-off subscription.

## [1.5.1]

- Bundled `phorm` core bumped to `^1.4.1`: `WhereBuilder` now escapes columns
  structurally via the dialect instead of regex replacement over the generated
  SQL, fixing mis-escaping when a column name coincided with a word inside the
  SQL template (e.g. a column named `LOWER` or `DATE`) and properly escaping
  `SqlFunctionColumn` inner columns.

## [1.5.0]

- **BREAKING**: bundled `phorm` core bumped to `^1.4.0` — automatic timestamps
  (`created_at`, `updated_at`, `deleted_at`) are now written in UTC instead of
  local time. New records sort consistently across devices/timezones; rows
  written by earlier versions keep their local-time values.
- Migration `applied_at` timestamps are now written in UTC as well.

## [1.4.1]

- Raise the default `DB.isolateThreshold` from `50` to `2000`. Result-set
  parsing only moves to a background isolate once inline parsing would risk a
  dropped frame; below that the isolate spawn + row copy was pure overhead. See
  `benchmark/parse_benchmark.dart` in the `phorm` package for the measurements.
- Document the `isolateThreshold` tuning knob in the README.

## [1.4.0]

- Upgrade to `sqlite3` ^3.3.4, `sqlite3_flutter_libs` ^0.6.0 and `sqlite3_web`
  ^0.9.2. Migrate the isolate backends off the deprecated `dispose()` in favor
  of `close()`. Raises the Dart SDK floor to `>=3.10.0` (required by
  `sqlite3_web` 0.9).
- Add `topics` to `pubspec.yaml` for pub.dev discoverability.
- Note: the `phorm_generator` dev-dependency is temporarily pinned to
  `<1.4.0`, as generator 1.4.0 pulls analyzer 13 (`meta ^1.18.3`) which
  conflicts with the `meta` version pinned by the current Flutter SDK.

## [1.3.0]

- Auto-generated pivot tables (from `@ManyToMany(createPivot: true)`) are now
  created on database upgrade as well, not only on first creation: any
  `IF NOT EXISTS`-guarded statement in a table's schema is re-applied when the
  owning table already exists.
- Added an informational log line when a pivot table is created alongside its
  model table (e.g. `Also creating pivot table: user_roles`).

## [1.2.0]

- Bumped `phorm` dependency to `^1.2.0` (and `phorm_generator` dev dependency to
  `^1.2.0`), exposing the new `@Schema(generateFullService: ...)` option.
- Bumped `sqlite3_web` to `^0.4.1`.

## [1.1.0]

- Bumped `phorm` dependency to `^1.1.0` and `phorm_generator` (dev) to `^1.1.0`.
- Version bump to keep all PHORM packages in sync.

## [1.0.3]

- Version bump to keep all PHORM packages in sync.

## [1.0.2]

- Updated SDK environment constraint to >=3.7.0 <4.0.0

## [1.0.1]

- Updated README with badges
- Removed commented workspace resolution configuration

## [1.0.0]

- First stable release of the PHORM SQLite Driver.
- Implements `phorm` runtime database execution layer on top of `sqlite3`.
- Dedicated multi-thread background isolate executor ensuring synchronous SQLite operations never block the main/UI thread.
- Out-of-the-box Flutter Web support via WebAssembly (`sqlite3_web`) and persistent IndexedDB file system.
- Transparent database versioning and smart idempotent migration lifecycle tracking via the `__phorm_migrations` table.
- High-performance slow query tracer and console loggers.
- Built-in SQLCipher encryption support for Native (iOS, Android, Desktop) platforms.
- Native Dart `SqlFunction` registration (including regexp support).
