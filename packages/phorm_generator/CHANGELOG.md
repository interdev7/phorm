# Changelog

## [1.6.0]

- **Positional row binders.** For every non-generic model with a generated
  `fromJson`, the generator now also emits `_$Phorm<Class>RowBinder` and
  wires it into the generated `Table` (`rowBinder:`). The binder mirrors all
  `fromJson` conversions (enums, `DateTime`, bool 0/1, converters, nested
  objects, relationship columns, timestamp/FK cascades) but reads row values
  positionally — powering the core's fastest read path. Requires
  `phorm_annotations ^1.8.0`.

## [1.5.0]

- **Automatic foreign-key indexes.** The generated schema now includes
  `CREATE INDEX IF NOT EXISTS <table>_<fk>_idx` for every `BelongsTo`/`Join`
  foreign key column, and an index on the related-key column of
  auto-generated `@ManyToMany(createPivot: true)` pivot tables (the composite
  primary key already covers the owner key). Without these indexes,
  relationship loading scans the child table once per parent row. Opt out
  per model with `@Schema(indexForeignKeys: false)`; requires
  `phorm_annotations ^1.7.0`. Existing databases pick the indexes up on
  upgrade via the `IF NOT EXISTS` re-run, or on any open with
  `DB(autoMigrate: true)`.

## [1.4.1]

- Re-enabled most `very_good_analysis` lints (the ignore list shrank from 27
  to 8). Internal cleanups with no behavior changes: catch clauses now use
  `on Object`, tear-offs instead of lambdas, explicit types where required.

## 1.4.0

- Migrate to the latest analyzer element model: `analyzer` ^13.3.0, `build`
  ^4.0.6, `source_gen` ^4.2.3 and `dart_style` ^3.1.9. Requires Dart SDK
  ^3.9.0 (bundled with Flutter 3.35+).
- Internal only: no changes to generated output. Existing `@Schema`-annotated
  models regenerate identically.
- Add `topics` to `pubspec.yaml` for pub.dev discoverability.

## 1.3.0

- Auto-generate the pivot table for `@ManyToMany(createPivot: true)`. The pivot
  `CREATE TABLE IF NOT EXISTS` (two foreign-key columns + composite primary key)
  is appended to the model's schema, so it is created automatically at
  build_runner time and applied through migrations — no manual pivot setup.
- When `@ManyToMany(pivotForeignKeys: true)` is also set, the generated pivot
  table includes `FOREIGN KEY (...) REFERENCES ... ON DELETE CASCADE`
  constraints for both columns. Column types are inferred from each model's
  primary key.
- Bumped `phorm_annotations` dependency to `^1.3.0` (required for the new
  `createPivot` / `pivotForeignKeys` options).

## 1.2.0

- Added support for the new `@Schema(generateFullService: ...)` option. When
  set to `false`, the generator no longer emits the large pluralized static
  service class (e.g. `Users`); only the lightweight schema, table, mappers and
  `copyWith` are generated. Defaults to `true`, so existing output is unchanged.
- Bumped `phorm_annotations` dependency to `^1.2.0`, which also carries the
  `MigrationBuilder.build()` fix (previously dropped `columns`, `timestamps`,
  and `autoIncrement` when rebuilding a table via the fluent migration API).

## 1.1.0

- Added per-dialect schema generation driven by `@Schema(dialect: ...)`. DDL rules
  are now split into per-dialect strategies under `src/generators/<dialect>/`
  (`sqlite`, `postgres`, `mysql`); the entry point `PhormSchemaGenerator` dispatches
  by dialect. SQLite output is unchanged; Postgres/MySQL are scaffolds.
- Split custom SQL function generation by dialect (`<dialect>_function_generator`);
  `SqlFunctionGenerator` is renamed to `PhormFunctionGenerator` and delegates to a
  `FunctionGenerator` strategy (defaults to SQLite).
- Requires `phorm_annotations: ^1.1.0` (for `SqlDialectKind`).

## 1.0.3

- Lowered `analyzer` constraint to `>=6.4.1 <6.9.0` for compatibility with Dart 3.7 SDKs (avoids the unavailable `_macros` package).
- Updated element accessors to the matching analyzer API (`enclosingElement`, `getDisplayString(withNullability: true)`).

## 1.0.2

- Updated SDK environment constraint to >=3.7.0 <4.0.0
- Restored analyzer dependency to ^6.11.0 to resolve build errors

## 1.0.1

- Updated README with badges
- Removed commented workspace resolution configuration

## 1.0.0

- First stable release.
- Automatically generates optimized SQL schemas (tables, indices, foreign keys) and DDL from annotations.
- Produces type-safe relational model mixins (`_$PhormModelMixin`) and pluralized service accessors.
- Provides highly optimized `_$PhormModelFromJson` methods for fast JSON mapping.
- Integrates with `build_runner` and `source_gen` for hot-reloadable, automated code generation.
