# Changelog

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
