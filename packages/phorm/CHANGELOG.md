# Changelog

## [1.6.0]

- **Keyset (cursor) pagination** — `PhormQuery.after(lastModel)` returns rows
  strictly after the given model in the current `orderBy` ordering. The
  primary key is appended automatically as a tiebreaker (to both ORDER BY and
  the cursor), duplicates and mixed ASC/DESC sorts are handled, and unlike
  `offset` the page stays stable under concurrent inserts/deletes. `SortBuilder`
  now exposes its structured `entries`.
- Fluent query API extensions on `PhormQuery`:
  - `distinct()` — `SELECT DISTINCT`;
  - `select([...])` — column subset shorthand for
    `attributes(Attributes.include([...]))`, accepts `PhormColumn`s or names;
  - `groupBy([...])` + `having(condition)` — grouping with a typed HAVING
    condition (explicit `groupBy` replaces the automatic primary-key grouping
    used for join deduplication);
  - `rows()` — executes the query and returns raw rows without model mapping,
    for grouped/aggregate results;
  - `noLimit()` — removes the default limit of 20 rows.
- `PhormCore.readRows(...)` — row-level counterpart of `readAll` (same
  soft-delete handling, no model mapping); `readAll`/`readAllWithCount` accept
  `limit: null` (no LIMIT) and `distinct`.
- `WhereBuilder.build` accepts an optional shared `ParamIndex`, so WHERE and
  HAVING number their placeholders sequentially in `$n` dialects.

## [1.5.0]

- **New: condition composition with `&` / `|`** — typed conditions now combine
  into AND/OR groups without dropping down to `WhereBuilder`:
  `Users.where(UserTable.age.gt(18) & (UserTable.city.eq('Sofia') | UserTable.city.eq('Plovdiv')))`
  compiles to `age > ? AND (city = ? OR city = ?)`. Groups nest freely; Dart's
  operator precedence (`&` over `|`) matches SQL. Requires
  `phorm_annotations ^1.5.0` (which introduces `PhormConditionGroup`).
- Re-enabled most `very_good_analysis` lints (the ignore list shrank from 25
  to 7 deliberate style rules): documented the remaining public members,
  `on FormatException` instead of a bare catch in JSON parsing, removed an
  unnecessary await. No API or behavior changes.

## [1.4.2]

- Internal refactor, no API changes: `core.dart` and `where_builder.dart`
  split into focused files — JOIN/JSON-aggregation query building extracted
  into `JoinQueryBuilder` (`PhormCore.buildJoinQuery` now delegates to it),
  the sealed condition hierarchy moved to a `where_condition.dart` part, and
  `WhereBuilderExtensions`/`WhereBuilders` moved to
  `where_builder_helpers.dart` (still exported from `package:phorm/phorm.dart`).

## [1.4.1]

- `WhereBuilder` now compiles conditions structurally: the column is stored
  separately from the SQL template and escaped via `SqlDialect.escapeIdentifier`
  directly, instead of regex word-boundary replacement over the generated SQL.
  Fixes potential mis-escaping when a column name coincided with a word inside
  the SQL template (e.g. a column named `LOWER` or `DATE`), and
  `SqlFunctionColumn` inner columns are now properly escaped.
  `raw()` conditions remain verbatim (no escaping), as before.
- Internal condition storage is a sealed class hierarchy instead of `dynamic`.

## [1.4.0]

- **BREAKING**: automatic timestamps (`created_at`, `updated_at`, `deleted_at`)
  are now written in UTC (`DateTime.now().toUtc()`) instead of local time.
  New records sort consistently across devices/timezones; rows written by
  earlier versions keep their local-time values.

## [1.3.0]

- Bumped `phorm_annotations` dependency to `^1.3.0`, which adds the
  `@ManyToMany(createPivot: ...)` and `@ManyToMany(pivotForeignKeys: ...)`
  options (re-exported by `phorm`) for automatically generating the pivot
  (join) table of a many-to-many relationship.

## [1.2.0]

- Bumped `phorm_annotations` dependency to `^1.2.0`, which adds the
  `@Schema(generateFullService: ...)` option (re-exported by `phorm`) and
  carries the `MigrationBuilder.build()` fix (previously dropped `columns`,
  `timestamps`, and `autoIncrement` when rebuilding a table via the fluent
  migration API).

## [1.1.0]

- Bumped `phorm_annotations` dependency to `^1.1.0` (adds `SqlDialectKind` and the
  `@Schema(dialect: ...)` option).
- Version bump to keep all PHORM packages in sync.

## [1.0.3]

- Version bump to keep all PHORM packages in sync.

## [1.0.2]

- Updated SDK environment constraint to >=3.7.0 <4.0.0
- Updated README with badges

## [1.0.1]

- Changed license to MIT
- Changed logo
- Updated README

## [1.0.0]

- First stable release of the PHORM Core.
- Driver-agnostic runtime query builder (`WhereBuilder`, `SortBuilder`).
- Generic CRUD service (`PhormCore<T extends Model>`) with optional `DatabaseExecutor` for transaction support.
- Seamless relational eager loading through Single-Query JSON Aggregation.
- Complete support for soft deletes (Paranoid mode) and automatic date timestamps.
- Native transaction wrapper and batch operation helpers (`insertBatch`, `updateBatch`, `deleteBatch`, etc.).
