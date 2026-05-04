# SQFlow — Overview

SQFlow is a lightweight, type-safe SQLite ORM abstraction for Dart and Flutter. It is built on top of [sqflite](https://pub.dev/packages/sqflite) and provides a fluent, declarative API for defining schemas, loading related data, and performing CRUD operations — all without raw SQL concatenation.

---

## Why SQFlow?

| Problem | SQFlow Solution |
| :--- | :--- |
| N+1 queries when loading related models | Single-query JSON aggregation (`json_group_array`) |
| SQL injection via raw string queries | Parameterized `WhereBuilder` (all values as `?`) |
| Manual `toJson`/`fromJson`/`copyWith` boilerplate | Code generation via `sqflow_generator` |
| Complex migration management | Versioned `MigrationBuilder` with `__sqflow_migrations` tracking table |
| Repetitive timestamp handling | Automatic `created_at`/`updated_at` injection |
| No type safety for relationship includes | Compile-safe `Includable.model<T>()` API |

---

## Architecture

```
┌────────────────────────────────────────┐
│             Your Flutter App           │
└──────────────────┬─────────────────────┘
                   │
┌──────────────────▼─────────────────────┐
│           SqflowCore<T>                │
│  readAll · readAsync · insertAsync     │
│  deleteAsync · transaction · batch     │
└──────┬───────────────────┬────────────┘
       │                   │
┌──────▼──────┐   ┌────────▼────────┐
│ WhereBuilder│   │  SortBuilder    │
│  (WHERE)    │   │  (ORDER BY)     │
└──────┬──────┘   └─────────────────┘
       │
┌──────▼──────────────────────────────┐
│               DB                    │
│  Lazy connection · Migration engine │
└──────────────────────────────────────┘
```

---

## Package Structure

| Package | Role |
| :--- | :--- |
| `sqflow_platform_interface` | Annotations (`@Schema`, `@Column`, `@ID`), data types, relationship definitions |
| `sqflow_core` | Runtime: `SqflowCore<T>`, `DB`, `WhereBuilder`, `SortBuilder` |
| `sqflow_generator` | `build_runner` plugin that generates mixins, SQL, and serialization code |

---

## Quick Install

```yaml
# pubspec.yaml
dependencies:
  sqflow_core: ^latest
  sqflite: ^latest

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
  @ID(type: TEXT())
  @override
  final String id;

  @Column(type: TEXT())
  final String name;

  User({required this.id, required this.name});

  @override
  Map<String, dynamic> toJson() => _$SQFlowUserToJson();

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}

// 2. Run the generator
// dart run build_runner build

// 3. Create service
final db = DB(databaseName: 'app.db', version: 1, tables: [usersTable]);
final userService = SqflowCore<User>(dbManager: db, table: usersTable);

// 4. Use it
await userService.insertAsync(User(id: 'u1', name: 'Alice'));
final user = await userService.readAsync('u1');
final result = await userService.readAll();
final paged = await userService.readAllWithCount(
  limit: 20,
  offset: 0,
);
print('Page: ${paged.data.length} / Total: ${paged.count}');
```
