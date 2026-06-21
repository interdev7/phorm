# PHORM MySQL 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.5.0-blue?logo=dart)](https://dart.dev)

> [!WARNING]
> **🚧 This package is under active development and is not yet functional.**
> The API is unstable and subject to change. Do not use in production.

A MySQL driver for the [PHORM](https://github.com/interdev7/phorm) — a lightweight, type-safe, driver-agnostic ORM for Dart and Flutter.

## Roadmap

- [ ] MySQL dialect (`SqlDialect` implementation)
- [ ] Connection pool management
- [ ] Async query executor
- [ ] Migration support
- [ ] Dart server support

## Usage (planned)

```dart
import 'package:phorm_mysql/phorm_mysql.dart';

final db = PhormMysqlDatabase(
  host: 'localhost',
  port: 3306,
  database: 'mydb',
  username: 'root',
  password: 'secret',
  tables: [usersTable],
);

final users = PhormCore<User>(dbManager: db, table: usersTable);
await users.insert(user);
```

## Related packages

| Package                         | Description                          |
| :------------------------------ | :----------------------------------- |
| [phorm_sqlite](../phorm_sqlite) | ✅ Stable SQLite driver              |
| [phorm](../phorm)               | Core engine (included automatically) |

## License

MIT © 2024–2026 PHORM Contributors
