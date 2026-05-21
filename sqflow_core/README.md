# SQFlow Core

[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)](https://dart.dev/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

The runtime engine of the SQFlow ORM — CRUD, batch operations, pagination, eager loading, soft deletes, transactions, and schema migrations. Built on top of [sqlite3](https://pub.dev/packages/sqlite3) with isolate-based architecture for non-blocking database operations.

---

## Motivation 🎯

SQFlow was created to solve three main problems in Flutter database management:

1. **Type Safety over Strings**: Most SQLite wrappers rely on `Map<String, dynamic>`. SQFlow generates type-safe columns and models, catching errors at compile-time rather than runtime.
2. **Active Record DX**: Instead of managing complex DAO/Repository layers, SQFlow provides a clean, declarative API directly on your models (`Users.insert()`, `Users.where(...)`).
3. **Performance & Relationships**: Fetching complex graphs (Many-to-Many, HasMany) usually leads to N+1 query problems. SQFlow uses JSON aggregation to resolve entire dependency trees in a **single SQL query**.

---

## Installation

```yaml
dependencies:
  sqflow_core: ^latest
  sqlite3: ^2.4.6
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
final user = await Users.readOne('id123');

// 4. Fluent Queries
final result = await Users.where(Users.age.gt(18)).get();

// 5. Traditional engine access
final userService = SqflowCore<User>(dbManager: appDb, table: usersTable);
final paged = await userService.readAllWithCount(limit: 20);
```

---

## Key Features

- **Full CRUD** — `insert`, `readOne`, `update`, `delete`, `restore`, `exists`
- **Batch operations** — `insertBatch`, `updateBatch`, `deleteBatch`, etc. (all in a single transaction)
- **Fluent query builder** — `WhereBuilder` with 30+ operators, SQL-injection safe
- **Two read methods** — `readAll()` → `Result<T>`, `readAllWithCount()` → `ResultWithCount<T>` (no cast required)
- **Eager loading** — `Includable.model<T>()` resolves relationships in a single query via JSON aggregation
- **Cross-table filtering** — dot-notation in `WhereBuilder` triggers automatic `LEFT JOIN`
- **Soft deletes** — paranoid mode with `withDeleted`, `onlyDeleted`, `restore`
- **Smart migrations** — versioned, idempotent, hash-tracked via `__sqflow_migrations` table

---

## CRUD Methods

| Method                  | Returns                      | Description               |
| :---------------------- | :--------------------------- | :------------------------ |
| `insert(item)`          | `Future<int>`                | Row ID                    |
| `update(item)`          | `Future<int>`                | Affected rows             |
| `upsert(item)`          | `Future<void>`               | Insert or replace         |
| `readOne(id)`           | `Future<T?>`                 | By primary key            |
| `readAll(...)`          | `Future<Result<T>>`          | Paginated list            |
| `readAllWithCount(...)` | `Future<ResultWithCount<T>>` | List + total count        |
| `delete(id)`            | `Future<int>`                | Soft or hard delete       |
| `restore(id)`           | `Future<int>`                | Un-delete (paranoid only) |
| `exists(id)`            | `Future<bool>`               | Check presence            |
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

| [10-validators.md](../docs/10-validators.md) | Built-in validators (NotEmpty, Email, Range…) |
| [11-many-to-many.md](../docs/11-many-to-many.md) | Pivot tables and Many-to-Many setup |
| [12-query-builder.md](../docs/12-query-builder.md) | Fluent API reference — `.get()`, `.first()` |
| [13-seeders-and-factories.md](../docs/13-seeders-and-factories.md) | Data seeding and mock factories |

---

## License

Apache 2.0
