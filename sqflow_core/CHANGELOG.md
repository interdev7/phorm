# Changelog

All notable changes for the sqflow_core package.

## 1.5.0 — 2026-05-16

- **BREAKING: Migrated from sqflite to sqlite3**: Complete rewrite of database layer using `sqlite3` package with isolate-based architecture.
- **Non-blocking operations**: All database operations now run in a separate isolate, preventing UI thread blocking.
- **Improved performance**: Direct FFI bindings to SQLite provide better performance than sqflite.
- **Cross-platform support**: Enhanced platform support with `path_provider` integration.
- **API compatibility**: Maintained full backward compatibility with existing sqflite-based API.
- **Test coverage**: All 117 tests passing with new sqlite3 implementation.

## 1.4.0 — 2026-05-14

- **Seeders & Factories**: Added `Seeder` abstract class and `Factory<T>` interface to `sqflow_platform_interface`.
- **`db.seed()`**: `DB` now exposes a `seed(List<Seeder>)` method for populating the database.
- **Validators**: Added `NotEmpty`, `Email`, `Range`, `MinLength`, `MaxLength`, and custom validators via the `json_validators.dart` API.
- **Fluent Query Builder**: Introduced `SqflowQuery<T>` with `.where()`, `.include()`, `.sort()`, `.limit()`, `.offset()`, `.get()`, `.first()` chaining.
- **Tests**: Added `seeders_test.dart` covering Factory creation and multi-seeder execution.

## 1.3.0 — 2026-05-08

- **Many-to-Many relationships**: Added `ManyToMany` relationship type with pivot table support.
- **Cross-table filtering**: Dot-notation in `WhereBuilder` now triggers automatic `LEFT JOIN` for ManyToMany, HasMany, HasOne, and BelongsTo.

## 1.2.0 — 2026-05-01

- **`readOne`**: Renamed `readAsync` → `readOne` for API consistency. `readOne` sync variant added.
- **Deep loading**: Nested `Includable` support for arbitrary-depth relationship loading.
- **`watchOne` / `watchAll`**: Reactive streams for single record and collection watching.
- **Transactions with buffered notifications**: `DB.transaction()` buffers `changeStream` events and emits them only after a successful commit.

## 1.1.0 — 2026-04-28

- **ORM Relationships & Eager Loading**: Added support for `HasMany`, `HasOne`, and `BelongsTo` relationships.
- **`include` parameter**: Added `include` support to `readOne` and `readAll` for automatic fetching of related records.
- **Batch Loader**: Implemented an efficient batch loader for relationships to prevent the N+1 query problem.
- **New Annotations**: Integrated new relationship annotations for declarative schema definition.
- **Documentation**: Comprehensive updates to README.md with relationship usage examples.

## 1.0.0 — 2026-01-23

- First public release.
- CRUD service for SQLite with soft delete support.
- WhereBuilder for complex filters (AND/OR groups, inList, like, dateOnlyBetween, isNull/isTrue).
- Batch operations: insertBatch, updateBatch, deleteBatch, restoreBatch.
- SortBuilder for sorting by multiple fields.
- Table schema and index management (IndexProps).
- Tests based on in-memory SQLite environment.
