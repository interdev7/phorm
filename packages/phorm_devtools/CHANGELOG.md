# Changelog

## 0.1.0

- Initial release: `enablePhormDevtools(db)` attaches the Phorm Studio DevTools bridge in debug builds.
- Service extensions: `ext.phorm.getInfo`, `listDatabases`, `getTables`, `queryData`, `mutateData`, `rawSql`, `getMigrations`, `getQueryDetails`, `getActiveStreams`.
- Throttled `phorm.queryBatch` events (100 ms batching, 1000-entry ring buffer, 4 KB SQL truncation with pull-based details).
- Watch stream tracking (`watchOne`/`watchAll` lifecycle and emit counts) via `PhormInstrumentation`.
- Multi-database support (`dbId` parameter on every method).
- Entire bridge is compiled out of release/profile builds via `assert`.
