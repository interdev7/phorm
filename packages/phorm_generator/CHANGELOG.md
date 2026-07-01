# Changelog

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
