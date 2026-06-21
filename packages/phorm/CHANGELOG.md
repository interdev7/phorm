# Changelog

## [1.0.0]

- Changed license to MIT
- Removed `resolution: workspace` from `pubspec.yaml`
- Changed logo
- Updated README

## [1.0.0]

- First stable release of the PHORM Core.
- Driver-agnostic runtime query builder (`WhereBuilder`, `SortBuilder`).
- Generic CRUD service (`PhormCore<T extends Model>`) with optional `DatabaseExecutor` for transaction support.
- Seamless relational eager loading through Single-Query JSON Aggregation.
- Complete support for soft deletes (Paranoid mode) and automatic date timestamps.
- Native transaction wrapper and batch operation helpers (`insertBatch`, `updateBatch`, `deleteBatch`, etc.).
