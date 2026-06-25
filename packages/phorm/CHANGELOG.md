# Changelog

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
