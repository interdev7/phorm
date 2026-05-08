<div align="center">
  <img src="assets/logo/sqflow_logo.png" alt="SqFlow" height="240" />
</div>

# SQFlow

A lightweight, type-safe SQLite ORM-like abstraction for Dart and Flutter.

SQFlow uses **Single-Query JSON Aggregation** to load relationships in a single SQL query, and provides a fluent, type-safe API for all database needs — without raw string concatenation.

---

## Packages

| Package | Description |
| :--- | :--- |
| [sqflow_core](./sqflow_core) | Runtime engine — CRUD, WhereBuilder, Transactions, Eager Loading |
| [sqflow_platform_interface](./sqflow_platform_interface) | Annotation library — `@Schema`, `@Column`, `@ID`, relationships |
| [sqflow_generator](./sqflow_generator) | Code generator — automates SQL schemas, `toJson`/`fromJson`, mixins |

---

## Key Features

- **🚀 Performance** — Load complex relationships in **exactly one** SQL query via JSON aggregation
- **🛡️ Type Safety** — No `dynamic` maps in queries; compile-safe `Includable.model<T>()`
- **🔍 Fluent API** — `WhereBuilder` and `SortBuilder` with full SQL injection protection
- **🔗 Cross-table Filtering** — Filter by related table columns with automatic `LEFT JOIN`
- **🗑️ Soft Deletes** — Built-in paranoid mode with restore support
- **📦 Batch & Transactions** — Atomic bulk operations
- **🔄 Smart Migrations** — Versioned, idempotent migration tracking

---

## Quick Start

```dart
@Schema(
  tableName: 'users',
  paranoid: true,
  relationships: [HasMany(model: Post, foreignKey: 'user_id')],
)
class User extends Model with _$SQFlowUserMixin {
  @ID()
  @override
  final String id;

  @Column()
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}
```

```dart
// 1. Fluent API (New & Recommended) 🌟
final myPosts = await Posts.where(Posts.title.like('Dart%')).get();

// 2. Complex queries with relationships
final result = await Users.query
  .where(Posts.title.like('Dart%'))
  .include([Includable.model<Post>()])
  .get();

// 3. Traditional SqflowCore instance (if needed)
final paged = await userService.readAllWithCount(
  where: WhereBuilder().like('posts.title', 'Dart%'),
  limit: 20,
  offset: 0,
);
```
print('Showing ${paged.data.length} of ${paged.count}');
```

---

## Documentation

Full documentation is in the [`docs/`](./docs) folder:

| File | Contents |
| :--- | :--- |
| [01-overview.md](./docs/01-overview.md) | Architecture, why SQFlow, package structure |
| [02-schema-definition.md](./docs/02-schema-definition.md) | `@Schema`, `@Column`, `@ID`, data types, indexes, CHECK |
| [03-where-builder.md](./docs/03-where-builder.md) | All WhereBuilder methods, groups, cross-table filtering, pitfalls |
| [04-crud-operations.md](./docs/04-crud-operations.md) | Insert, Read, Update, Delete, Batch, Transactions, Attributes |
| [05-relationships.md](./docs/05-relationships.md) | HasMany, HasOne, BelongsTo, Includable API, fromJson patterns |
| [06-db-and-migrations.md](./docs/06-db-and-migrations.md) | DB manager, MigrationBuilder, version lifecycle |
| [07-code-generation.md](./docs/07-code-generation.md) | Generator setup, commands, generated code anatomy |
| [08-soft-deletes.md](./docs/08-soft-deletes.md) | Paranoid mode, restore, hard delete |
| [09-pitfalls-and-limitations.md](./docs/09-pitfalls-and-limitations.md) | Known issues, gotchas, design trade-offs |

---

## 📄 License

Apache 2.0
