<div align="center">
  <!-- <img src="assets/logo/logo.png" alt="phorm" height=250/> -->
  <img src="assets/logo/phorm.png" alt="phorm" height=450/>
</div>

# PHORM (***P***redictable ***H***armonious **_ORM_**)

A lightweight, type-safe, driver-agnostic ORM for Dart and Flutter.

**PHORM** is designed from the ground up to be database-independent. It separates query building and relationship mapping from database-specific SQL grammar using a pluggable **Dialect system**. This allows using the same declarative models and generated service APIs across multiple SQL backends, starting with SQLite (via `phorm_sqlite`) and expanding to PostgreSQL, MySQL and more in the future.

By leveraging **Single-Query JSON Aggregation**, PHORM aggregates complex parent-child relationship trees into a **single, highly-optimized SQL query** using database-native JSON capabilities (such as SQLite's `json_group_array` or PostgreSQL's `jsonb_agg`), offering stellar performance and zero N+1 query overhead.

## Architecture

<p align="center">
  <img src="assets/diagrams/diagram_1.png" alt="Phorm Architecture" />
</p>

---

## Packages

| Package                                                | Description                                                                  |
| :----------------------------------------------------- | :--------------------------------------------------------------------------- |
| [phorm](./)                                            | Root package & Core engine — CRUD, WhereBuilder, Transactions, Eager Loading |
| [phorm_sqlite](./phorm_sqlite)                         | SQLite driver — Connection manager, isolates, web WASM support               |
| [phorm_platform_interface](./phorm_platform_interface) | Annotation library — `@Schema`, `@Column`, `@ID`, relationships              |
| [phorm_generator](./phorm_generator)                   | Code generator — automates SQL schemas, `toJson`/`fromJson`, mixins          |

---

## Motivation 🎯

PHORM was created to solve three main problems in Flutter database management:

1. **Type Safety over Strings**: Most SQLite wrappers rely on `Map<String, dynamic>`. PHORM generates type-safe columns and models, catching errors at compile-time rather than runtime.
2. **Active Record DX**: Instead of managing complex DAO/Repository layers, PHORM provides a clean, declarative API directly on your models (`Users.insert()`, `Users.where(...)`).
3. **Performance & Relationships**: Fetching complex graphs (Many-to-Many, HasMany) usually leads to N+1 query problems. PHORM uses JSON aggregation to resolve entire dependency trees in a **single SQL query**.

---

## Installation

Add `phorm` and a driver like `phorm_sqlite` to your dependencies:

```yaml
dependencies:
  phorm: ^latest
  phorm_sqlite: ^latest # The SQLite driver and connection manager
```

---

## Quick Start

```dart
import 'package:phorm_sqlite/phorm_sqlite.dart'; // Import phorm_sqlite for DB and connection execution

// 1. Table configuration (generated)
final usersTable = Table<User>(...);

// 2. DB manager (from phorm_sqlite)
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
final userService = PhormCore<User>(dbManager: appDb, table: usersTable);
// Or
final userService = appDb.service<User>();
final paged = await userService.readAllWithCount(limit: 20);
```

---

## Key Features

- **🚀 Performance** — Load complex relationships in **exactly one** SQL query via JSON aggregation
- **🛡️ Type Safety** — No `dynamic` maps in queries; compile-safe `Includable.model<T>()`
- **🔍 Fluent API** — `WhereBuilder` and `SortBuilder` with full SQL injection protection
- **🔗 Cross-table Filtering** — Filter by related table columns with automatic `LEFT JOIN`
- **🗑️ Soft Deletes** — Built-in paranoid mode with restore support
- **📦 Batch & Transactions** — Atomic bulk operations
- **🔄 Smart Migrations** — Versioned, idempotent migration tracking
- **🌐 Flutter Web** — WebAssembly (WASM) backend with IndexedDB persistence, zero code changes

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

```dart
Users.where(Users.status.eq('active'))
  .where(Users.age.gt(18))
  .where(Users.name.like('%John%'))
  .get();

// Manual WhereBuilder still works
WhereBuilder().eq(Users.status, 'active').gt(Users.age, 18);
```

---

## Documentation

Full documentation is in the [`docs/`](./docs) folder:

| File                                                                  | Contents                                                          |
| :-------------------------------------------------------------------- | :---------------------------------------------------------------- |
| [01. Overview](./docs/01-overview.md)                                 | Architecture, why PHORM, package structure                        |
| [02. Schema Definition](./docs/02-schema-definition.md)               | `@Schema`, `@Column`, `@ID`, data types, indexes, CHECK           |
| [03. Where Builder](./docs/03-where-builder.md)                       | All WhereBuilder methods, groups, cross-table filtering, pitfalls |
| [04. CRUD Operations](./docs/04-crud-operations.md)                   | Insert, Read, Update, Delete, Batch, Transactions, Attributes     |
| [05. Relationships](./docs/05-relationships.md)                       | HasMany, HasOne, BelongsTo, Includable API, fromJson patterns     |
| [06. DB and Migrations](./docs/06-db-and-migrations.md)               | DB manager, MigrationBuilder, version lifecycle                   |
| [07. Code Generation](./docs/07-code-generation.md)                   | Generator setup, commands, generated code anatomy                 |
| [08. Soft Deletes](./docs/08-soft-deletes.md)                         | Paranoid mode, restore, hard delete                               |
| [09. Pitfalls and Limitations](./docs/09-pitfalls-and-limitations.md) | Known issues, gotchas, design trade-offs                          |
| [10. Validators](./docs/10-validators.md)                             | Built-in validators (NotEmpty, Email, Range, etc.)                |
| [11. Many to Many](./docs/11-many-to-many.md)                         | Detailed guide on pivot tables and Many-to-Many setup             |
| [12. Query Builder](./docs/12-query-builder.md)                       | Fluent API reference — .get(), .first(), chaining                 |
| [13. Seeders and Factories](./docs/13-seeders-and-factories.md)       | Data seeding and mock generation for testing                      |
| [14. Reactivity](./docs/14-reactivity.md)                             | Reactive streams, watchOne(), watchAll(), updatesSync integration |
| [15. Flutter Web](./docs/15-flutter-web.md)                           | **Flutter Web / WASM** — setup, IndexedDB persistence, limits     |

---

## License

Apache 2.0
