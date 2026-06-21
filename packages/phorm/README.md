<div align="center">
  <img src="../../assets/logo/phorm.png" alt="phorm" height=300/>
</div>

# PHORM Core 🚀

[![Pub Version](https://img.shields.io/pub/v/phorm.svg)](https://pub.dev/packages/phorm)
[![Build Status](https://github.com/interdev7/phorm/actions/workflows/main.yml/badge.svg)](https://github.com/interdev7/phorm/actions)
[![Coverage](https://codecov.io/gh/interdev7/phorm/branch/main/graph/badge.svg?flag=phorm)](https://codecov.io/gh/interdev7/phorm)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.5.0-blue?logo=dart)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-compatible-54C5F8?logo=flutter)](https://flutter.dev)

**`phorm`** is the core runtime engine of **PHORM** (Predictable Harmonious ORM) — a lightweight, type-safe, and driver-agnostic ORM for Dart and Flutter.

It defines the unified interface for queries, transactions, soft deletes, and complex parent-child relationships, delegating the low-level database execution to specific driver packages (such as `phorm_sqlite`).

---

## 📦 Modular Architecture

PHORM is split into focused packages to keep your production apps lightweight:

1. **`phorm`** (This Package) — **The core runtime engine**. Handles CRUD APIs, query assembly (`WhereBuilder`, `SortBuilder`), paranoid soft deletes, relationships, and transaction wrappers.
2. **`phorm_annotations`** — Database-independent annotations (`@Schema`, `@Column`, `@ID`) and logical type definitions.
3. **`phorm_generator`** — Code generator (`build_runner`) that automates type-safe model mixins, JSON builders, and runtime table configurations.
4. **`phorm_sqlite`** — **The SQLite driver**. Implements connection pool management, background isolates (Native), WebAssembly persistence (Web), and database migrations.

---

## ⚡ Key Core Features

- **🔌 Pluggable Dialect Architecture** — Write code once. The core uses a flexible `SqlDialect` interface to compile SQL parameters, escape identifiers, and structure queries. The same models and service APIs work across SQLite, and can expand to PostgreSQL or MySQL in the future.
- **📊 Single-Query JSON Aggregation** — Eager load complex parent-child relation trees (e.g., `User` ➔ `Posts` ➔ `Comments` ➔ `Author`) in **exactly one highly-optimized SQL query** using database-native JSON capabilities, resolving the notorious N+1 query problem with ease.
- **🛡️ Type-Safe Querying** — Generate strongly-typed column accessors. Write compile-time safe queries without raw maps or magical string keys.
- **🗑️ Paranoid Soft Deletes** — Seamless, built-in soft delete support. Query filters exclude soft-deleted records by default, with complete `restore()` and force delete capabilities.

---

## 🚀 Usage Example

### 1. Define Your Model (in `user.dart`)

Use `phorm_annotations` to define the database entity structure:

```dart
import 'package:phorm/phorm.dart';

part 'user.sql.g.dart';

@Schema(tableName: 'users', paranoid: true)
class User extends Model with _$PhormUserMixin {
  @ID()
  final String id;

  @Column()
  final String name;

  @Column()
  final int age;

  User({required this.id, required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) => _$PhormUserFromJson(json);
}
```

### 2. Run the Query (Driver Agnostic)

Once compiled via `build_runner`, you interact with your database using generated, fluent service APIs:

```dart
import 'package:phorm_sqlite/phorm_sqlite.dart'; // Import specific execution driver

// Initialize your database (managed by phorm_sqlite)
final db = DB.autoVersion(
  databaseName: 'app.db',
  tables: [usersTable],
);

// Resolve your type-safe CRUD service
final userService = db.service<User>();

// 1. Insert a record
await userService.insert(User(id: 'u1', name: 'Alice', age: 24));

// 2. Complex Fluent Query
final activeAdults = await userService.query
    .where(Users.age.gt(18))
    .where(Users.name.like('A%'))
    .get();

// 3. Eager load relationships in a single query
final usersWithPosts = await userService.query
    .include(['posts', 'profile'])
    .get();
```

---

## 🛠️ Pluggable Query Builder Highlights

The `WhereBuilder` matches SQL capabilities with Dart's type-safety:

```dart
Users.where(Users.age.between(18, 65))
     .where(Users.status.inList(['active', 'pending']))
     .where(Users.name.like('%Smith%'))
     .get();
```

All filters support operator overloading and logical groups:

```dart
Users.where(Users.age.gt(30) & (Users.role.eq('admin') | Users.role.eq('editor'))).get();
```

---

## 📄 License

MIT License
