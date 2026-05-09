# SQFlow Core

[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)](https://dart.dev/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

The runtime engine of the SQFlow ORM — CRUD, batch operations, pagination, eager loading, soft deletes, transactions, and schema migrations. Built on top of [sqflite](https://pub.dev/packages/sqflite).

---

## Installation

```yaml
dependencies:
  sqflow_core: ^latest
  sqflite: ^latest
```

---

## Quick Start

```dart
// 1. Table configuration (generated)
final usersTable = Table<User>(...);

// 2. DB manager
final appDb = DB.autoVersion(
  databaseName: 'app.db',
  tables: [usersTable],
);

// 3. Service API (Recommended) 🌟
await Users.insert(user);
final user = await Users.read('id123');

// 4. Fluent Queries
final result = await Users.where(Users.age.gt(18)).get();

// 5. Traditional engine access
final userService = SqflowCore<User>(dbManager: appDb, table: usersTable);
final paged = await userService.readAllWithCount(limit: 20);
```

---

## Key Features

- **Full CRUD** — `insertAsync`, `readAsync`, `updateAsync`, `deleteAsync`, `restoreAsync`, `existsAsync`
- **Batch operations** — `insertBatchAsync`, `updateBatchAsync`, `deleteBatchAsync`, etc. (all in a single transaction)
- **Fluent query builder** — `WhereBuilder` with 30+ operators, SQL-injection safe
- **Two read methods** — `readAll()` → `Result<T>`, `readAllWithCount()` → `ResultWithCount<T>` (no cast required)
- **Eager loading** — `Includable.model<T>()` resolves relationships in a single query via JSON aggregation
- **Cross-table filtering** — dot-notation in `WhereBuilder` triggers automatic `LEFT JOIN`
- **Soft deletes** — paranoid mode with `withDeleted`, `onlyDeleted`, `restoreAsync`
- **Smart migrations** — versioned, idempotent, hash-tracked via `__sqflow_migrations` table

---

## CRUD Methods

| Method                  | Returns                      | Description               |
| :---------------------- | :--------------------------- | :------------------------ |
| `insertAsync(item)`     | `Future<int>`                | Row ID                    |
| `updateAsync(item)`     | `Future<int>`                | Affected rows             |
| `upsertAsync(item)`     | `Future<int>`                | Insert or replace         |
| `readAsync(id)`         | `Future<T?>`                 | By primary key            |
| `readAll(...)`          | `Future<Result<T>>`          | Paginated list            |
| `readAllWithCount(...)` | `Future<ResultWithCount<T>>` | List + total count        |
| `deleteAsync(id)`       | `Future<int>`                | Soft or hard delete       |
| `restoreAsync(id)`      | `Future<int>`                | Un-delete (paranoid only) |
| `existsAsync(id)`       | `Future<bool>`               | Check presence            |
| `transaction(fn)`       | `Future<R>`                  | Raw transaction           |

All methods have fire-and-forget variants: `insert(item, onSuccess: ..., onError: ...)`.

---

## WhereBuilder Highlights

Users.where(Users.status.eq('active'))
.where(Users.age.gt(18))
.where(Users.name.like('%John%'))
.get();

// Manual WhereBuilder still works

```dart
WhereBuilder().eq(Users.status, 'active').gt(Users.age, 18);
```

---

## Learn More

Full documentation is in the [`docs/`](../docs) folder:

| File                                                                     | Contents                                |
| :----------------------------------------------------------------------- | :-------------------------------------- |
| [01-overview.md](../docs/01-overview.md)                                 | Architecture, package structure         |
| [02-schema-definition.md](../docs/02-schema-definition.md)               | `@Schema`, `@Column`, `@ID`, data types |
| [03-where-builder.md](../docs/03-where-builder.md)                       | All WhereBuilder methods and pitfalls   |
| [04-crud-operations.md](../docs/04-crud-operations.md)                   | CRUD, Batch, Transactions, Attributes   |
| [05-relationships.md](../docs/05-relationships.md)                       | HasMany, HasOne, Includable API         |
| [06-db-and-migrations.md](../docs/06-db-and-migrations.md)               | DB manager, MigrationBuilder            |
| [07-code-generation.md](../docs/07-code-generation.md)                   | Generator setup, generated code anatomy |
| [08-soft-deletes.md](../docs/08-soft-deletes.md)                         | Paranoid mode, restore, hard delete     |
| [09-pitfalls-and-limitations.md](../docs/09-pitfalls-and-limitations.md) | Known issues and gotchas                |

---

## License

Apache 2.0
