# phorm_postgres

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.5.0-blue?logo=dart)](https://dart.dev)

> [!WARNING]
> **🚧 This package is under active development and is not yet functional.**
> The API is unstable and subject to change. Do not use in production.

A PostgreSQL driver for the [PHORM ORM](https://github.com/interdev7/phorm) — a lightweight, type-safe, driver-agnostic ORM for Dart and Flutter.

## Roadmap

- [ ] PostgreSQL dialect (`SqlDialect` implementation)
- [ ] Connection pool management
- [ ] Async query executor
- [ ] Migration support
- [ ] Flutter & Dart server support

## Usage (planned)

```dart
import 'package:phorm_postgres/phorm_postgres.dart';

final db = PhormPostgresDatabase(
  host: 'localhost',
  port: 5432,
  database: 'mydb',
  username: 'postgres',
  password: 'secret',
  tables: [usersTable],
);

final users = PhormCore<User>(dbManager: db, table: usersTable);
await users.insert(user);
```

## Related packages

| Package | Description |
| :--- | :--- |
| [phorm_sqlite](../phorm_sqlite) | ✅ Stable SQLite driver |
| [phorm](../phorm) | Core engine (included automatically) |

## License

MIT © 2024–2026 PHORM Contributors
