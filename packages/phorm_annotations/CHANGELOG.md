# Changelog

## [1.8.0]

- New `PhormRowBinder<T>` typedef and optional `Table.rowBinder`: a
  positional row factory that resolves column indices once per result set
  and builds models by direct list reads. Added the `phormDecodeJson`
  helper used by generated binders to keep JSON-column semantics identical
  to the map-based path.

## [1.7.0]

- New `@Schema(indexForeignKeys: ...)` option (default `true`): the generator
  creates indexes on `BelongsTo`/`Join` foreign key columns and on
  auto-generated pivot tables. Set to `false` to opt out.

## [1.6.0]

- `PhormColumn.inList` / `notInList` accept `strict: true`, throwing an
  `ArgumentError` on an empty list instead of the lenient defaults
  (always-false condition for `inList`, no condition for `notInList`).

## [1.5.0]

- **New: `PhormConditionGroup` and `&` / `|` operators on `PhormCondition`** —
  typed conditions compose into AND/OR groups:
  `age.gt(18) & (city.eq('Sofia') | city.eq('Plovdiv'))`. Consecutive
  same-operator combinations flatten into one group; Dart's operator
  precedence (`&` over `|`) matches SQL. Consumed by `phorm >= 1.5.0`, which
  compiles the groups into parenthesized SQL.

## [1.4.3]

- Documented the entire public API (`public_member_api_docs` is now enforced)
  and cleaned up doc comment references.
- Re-enabled most `very_good_analysis` lints (the ignore list shrank from 28
  to 7 deliberate style rules); minor internal cleanups with no API changes
  (`unnecessary_await_in_return`, string escaping).

## [1.4.2]

- Docs: show how to do CRUD with `generateFullService: false` — register
  `usersTable` and resolve `db.service<User>()` (a `PhormCore<User>`).
  No code changes.

## [1.4.1]

- Docs: clarify how to choose a column's SQL type — `type:` (typed `SqlType`) →
  `sqlType:` (raw string) → `converter:` (complex objects) → inferred — and that
  the deprecated `SqlTypes` constants should no longer be used (README + guides).
  No code changes.

## [1.4.0]

- Deprecate the `SqlTypes` string-constant class (`SqlTypes.text`, …). Use the
  typed `SqlType` hierarchy via `@Column(type: ...)` (e.g. `TEXT()`,
  `VARCHAR(255)`), or a raw `@Column(sqlType: '...')` string for exotic DDL.
  `SqlTypes` will be removed in a future release.
- Add `topics` to `pubspec.yaml` for pub.dev discoverability.

## [1.3.0]

- Added `createPivot` to `@ManyToMany` (defaults to `false`). When `true`, the
  code generator emits a `CREATE TABLE IF NOT EXISTS` for the pivot table
  automatically (two foreign-key columns plus a composite primary key), so it no
  longer has to be created manually.
- Added `pivotForeignKeys` to `@ManyToMany` (defaults to `false`). When used
  together with `createPivot`, the generated pivot table also includes
  `FOREIGN KEY (...) REFERENCES ... ON DELETE CASCADE` constraints for both
  columns.

## [1.2.0]

- Added `generateFullService` to `@Schema` (defaults to `true`). When set to
  `false`, the generator skips the large pluralized static service class
  (e.g. `Users`, with the full CRUD/query API and column constants) and emits
  only the lightweight artefacts (schema, table, `fromJson`/`toJson`,
  `copyWith`). Fully backward compatible — existing models are unaffected.

## [1.1.2]

- Fixed `MigrationBuilder.build()` dropping the `columns`, `timestamps`, and
  `autoIncrement` fields when rebuilding the `Table`. The lost `columns`
  produced empty relationship JSON aggregation (broken serialization of
  eager-loaded relations), and a reset `timestamps` flag caused `created_at`/
  `updated_at` to be injected for tables that disabled timestamps. These
  fields are now carried over from the source table.

## [1.1.1]

- Documentation only: documented the `@Schema(dialect: ...)` option, the
  `@Column(type: ...)` typed SQL types, and the dialect-organised `SqlType`
  hierarchy in the README. No API changes.

## [1.1.0]

- Added `SqlDialectKind` enum (`sqlite`, `postgres`, `mysql`) and a `dialect` field
  on `@Schema` so the generator knows which database flavour to emit DDL for
  (defaults to `SqlDialectKind.sqlite`, fully backward compatible).
- Reorganised SQL types by dialect under `src/sql_types/` (`common_types`,
  `sqlite_types`, `postgres_types`, `mysql_types`). `src/sql_types.dart` is now a
  barrel re-exporting them, so existing type names (`VARCHAR`, `JSONB`, `Collate`,
  `SqlTypes`, …) are unchanged.

## [1.0.3]

- Version bump to keep all PHORM packages in sync.

## [1.0.2]

- Updated SDK environment constraint to >=3.7.0 <4.0.0

## [1.0.1]

- Changed license to MIT
- Updated README with badges
- Removed commented workspace resolution configuration

## 1.0.0

- First stable release.
- Table schema annotations: `@Schema`, `@Column`, `@ID`.
- Database relationship annotations: `@HasMany`, `@HasOne`, `@BelongsTo`, `@ManyToMany`, and `@Join`.
- Support for customizable naming strategies, indexes, and custom JSON serialization options.
- Declarative CHECK validators (e.g. `NotEmptyValidator`, `EmailValidator`).
- Support for database-independent logical types mapping.
- Added `ValueConverter<D, S>` for custom Dart-to-SQL type mappings.
- Added test and seed utilities (`Factory<T>` and `Seeder` interfaces).
