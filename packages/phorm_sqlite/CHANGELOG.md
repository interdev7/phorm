# Changelog

## [1.0.3]

- Version bump to keep all PHORM packages in sync.

## [1.0.2]

- Updated SDK environment constraint to >=3.7.0 <4.0.0

## [1.0.1]

- Updated README with badges
- Removed commented workspace resolution configuration

## [1.0.0]

- First stable release of the PHORM SQLite Driver.
- Implements `phorm` runtime database execution layer on top of `sqlite3`.
- Dedicated multi-thread background isolate executor ensuring synchronous SQLite operations never block the main/UI thread.
- Out-of-the-box Flutter Web support via WebAssembly (`sqlite3_web`) and persistent IndexedDB file system.
- Transparent database versioning and smart idempotent migration lifecycle tracking via the `__phorm_migrations` table.
- High-performance slow query tracer and console loggers.
- Built-in SQLCipher encryption support for Native (iOS, Android, Desktop) platforms.
- Native Dart `SqlFunction` registration (including regexp support).
