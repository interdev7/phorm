# Changelog

All notable changes for the sqflow_core package.

## 1.1.0 — 2026-04-28

- **ORM Relationships & Eager Loading**: Added support for `HasMany`, `HasOne`, and `BelongsTo` relationships.
- **`include` parameter**: Added `include` support to `readAsync` and `readAll` for automatic fetching of related records.
- **Batch Loader**: Implemented an efficient batch loader for relationships to prevent the N+1 query problem.
- **New Annotations**: Integrated new relationship annotations for declarative schema definition.
- **Documentation**: Comprehensive updates to README.md and ANNOTATIONS.md with relationship usage examples.

## 1.0.0 — 2026-01-23

- First public release.
- CRUD service for SQLite with soft delete support.
- WhereBuilder for complex filters (AND/OR groups, inList, like, dateOnlyBetween, isNull/isTrue).
- Batch operations: insertBatchAsync, updateBatchAsync, deleteBatchAsync, restoreBatchAsync.
- SortBuilder for sorting by multiple fields.
- Table schema and index management (IndexProps).
- Tests based on sqflite_common_ffi for in-memory environment.
