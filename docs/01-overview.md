# SQFlow — Overview

SQFlow is a lightweight, type-safe SQLite ORM abstraction for Dart and Flutter. It is built on top of [sqlite3](https://pub.dev/packages/sqlite3) with isolate-based architecture for non-blocking database operations, and provides a fluent, declarative API for defining schemas, loading related data, and performing CRUD operations — all without raw SQL concatenation.

## Motivation

Modern database management in Flutter often forces a trade-off between **performance** and **developer experience**. SQFlow is designed to eliminate that trade-off by focusing on four core pillars:

### 1. Zero N+1 Queries (JSON Aggregation)

Traditional ORMs often fetch related data by running multiple queries (the N+1 problem) or using complex JOINs that duplicate parent data.

- **SQFlow Solution**: It uses SQLite's native `json_group_array` and `json_object` functions to fetch a primary record and all its relationships (HasMany, HasOne, BelongsTo) in **one single, optimized SQL query**. The data comes back as a tree, which the ORM deserializes instantly.

### 2. Fluent Type Safety

Writing SQL queries as strings is error-prone and hard to maintain.

- **SQFlow Solution**: The generator creates static typed columns for every model. Instead of `where: "name LIKE 'A%'"`, you write `Users.name.like('A%')`. This gives you autocomplete, compile-time checks, and prevents SQL injection by default.

### 3. Automatic Lifecycle Management

Most apps need the same patterns: "When was this created?", "Don't actually delete it, just mark it as deleted", "Validate this email before saving".

- **SQFlow Solution**: By adding a few parameters to the `@Schema` annotation, SQFlow automatically handles:
  - **Timestamps**: Injects `created_at` and `updated_at` without manual fields.
  - **Soft Deletes**: Automatically filters out "deleted" records and provides a `restore()` API.
  - **Validation**: Enforces rules (email, length, ranges) in both Dart and the SQL schema.

### 4. Boilerplate-Free Workflow

- **SQFlow Solution**: The generator doesn't just create `toJson/fromJson`. It generates a full **Service Class** (e.g., `Users`) with static methods for CRUD, transactions, and reactive streams (`watch`). No more manual repository patterns or DAOs.

---

## Architecture

```text
┌────────────────────────────────────────┐
│             Your Flutter App           │
└──────────────────┬─────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           Service Class (Users)         │
│    Type-safe static methods & columns   │
└──────┬─────────────────────┬────────────┘
       │                     │
┌──────▼────────┐   ┌────────▼───────────┐
│ SqflowCore<T> │   │  WhereBuilder      │
│ (The Engine)  │   │  (The Query)       │
└──────┬────────┘   └────────────────────┘
       │
┌──────▼──────────────────────────────┐
│               DB                    │
│  Lazy connection · Migration engine │
└─────────────────────────────────────┘
```

---

## Package Structure

| Package                     | Role                                                                            |
| :-------------------------- | :------------------------------------------------------------------------------ |
| `sqflow_platform_interface` | Annotations (`@Schema`, `@Column`, `@ID`), data types, relationship definitions |
| `sqflow_core`               | Runtime: `SqflowCore<T>`, `DB`, `WhereBuilder`, `SortBuilder`                   |
| `sqflow_generator`          | `build_runner` plugin that generates mixins, SQL, and serialization code        |

---

## Quick Install

```yaml
# pubspec.yaml
dependencies:
  sqflow_core: ^latest
  sqlite3: ^2.4.6

dev_dependencies:
  sqflow_platform_interface: ^latest
  sqflow_generator: ^latest
  build_runner: ^latest
```

---

## Minimal Example

```dart
// 1. Annotate your model
@Schema(tableName: 'users')
class User extends Model with _$SQFlowUserMixin {
  @ID()
  final String id;

  @Column()
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}

// 2. Run the generator
// dart run build_runner build

// 3. Initialize app database once
final appDb = DB(databaseName: 'app.db', version: 1, tables: [usersTable]);

// 4. Use the generated service class
await Users.insert(User(id: 'u1', name: 'Alice'));

final user = await Users.readOne('u1');

final list = await Users.where(Users.name.like('A%')).get();

final paged = await Users.readAllWithCount(limit: 20);
print('Page: ${paged.data.length} / Total: ${paged.count}');
```
