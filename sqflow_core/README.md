# 🚀 SQFlow (core)

<div style="padding-top: 50px;" align="center">
  <image src="https://github.com/interdev7/sqflow/blob/main/assets/logo/sqflow_logo_screen.png"  alt="SqFlow"  />
</div>

### 😎 Make your SQLite queries flow effortlessly

[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)](https://dart.dev/)
[![Pub](https://img.shields.io/pub/version/sqflow_core)](https://pub.dev/packages/sqflow_core)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready, flexible, generic CRUD service for SQLite databases in Flutter/Dart applications. Built on top of [sqflite](https://pub.dev/packages/sqflite), it provides automatic timestamp handling, soft deletes, batch operations, advanced querying with fluent builders, schema management, and optional code generation via annotations. Extend `SqflowCore<T>` for your models and get enterprise-grade database operations out of the box.

## ✨ Key Features

- **🔧 Full CRUD Operations** - Create, Read, Update, Delete with automatic timestamps
- **🗑️ Soft Deletes** - Mark records as deleted without removing them (optional)
- **📦 Batch Operations** - Insert/update/delete/upsert multiple records in transactions
- **🔍 Advanced Querying** - Fluent `WhereBuilder` for complex WHERE clauses, `SortBuilder` for ORDER BY
- **📊 Pagination with Total Count** - Built-in support for limit/offset with window function optimization
- **🔄 Schema Management** - Automatic table creation and migration tracking via migrations table + `MigrationBuilder`
- **⚡ Automated Generation** - Annotations (`@Schema`, `@Column`, `@ID`) for zero-boilerplate schemas and models
- **🔗 Type-Safe Eager Loading** - Fluent `Includable` API for resolving relationships without `dynamic` strings
- **🧪 Type Safety** - Generic over your models (`T extends Model`) with compile-time checks
- **🛡️ SQL Injection Protection** - Parameterized queries and column name validation
- **🎯 Performance Optimized** - Single query for pagination with COUNT(\*) OVER()
- **📱 UI-Friendly** - Both async and synchronous fire-and-forget methods

Perfect for Flutter apps needing a lightweight ORM-like experience without the overhead.

## 📋 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
  - [Step 1: Add Dependencies](#step-1-add-dependencies)
  - [Step 2: Define Your Model](#step-2-define-your-model)
  - [Step 3: Create SqflowCore](#step-3-create-databaseservice)
  - [Step 4: Initialize and Use](#step-4-initialize-and-use)
- [Architecture Overview](#-architecture-overview)
- [Core Components](#-core-components)
  - [DB: Database Manager](#db-database-manager)
  - [Model: Base Model Interface](#model-base-model-interface)
  - [Table<T>: Table Configuration](#tablet-table-configuration)
  - [SqflowCore<T>: Main CRUD Service](#databaseservicet-main-crud-service)
  - [WhereBuilder: Fluent Query Builder](#wherebuilder-fluent-query-builder)
  - [SortBuilder: Order By Builder](#sortbuilder-order-by-builder)
  - [DataAndCount<T>: Paginated Results](#dataandcountt-paginated-results)
- [Annotations & Code Generation](#-annotations--code-generation)
- [Advanced Usage](#-advanced-usage)
  - [Complex Queries](#complex-queries)
  - [Transactions](#transactions)
  - [Migrations](#migrations)
  - [Testing](#testing)
- [Best Practices](#best-practices)
- [Migration Guide](#migration-guide)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#-license)

## 🛠️ Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  sqflow_core: ^latest
  sqflite: ^latest
  # Optional: For code generation
  build_runner: ^latest
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### Step 1: Add Dependencies

See [Installation](#installation) above.

### Step 2: Define Your Model

All models must extend `Model`. Here's a simple `User` model:

```dart
import 'package:sqflow_core/sqflow_core.dart';

class User extends Model {
  @override
  final String id;
  final String name;
  final int? age;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  User({
    required this.id,
    required this.name,
    this.age,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'is_active': isActive ? 1 : 0,  // Booleans as 1/0 in SQLite
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  // Optional: copyWith method for updates
  User copyWith({
    String? id,
    String? name,
    int? age,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
```

### Step 3: Create SqflowCore

Define the table configuration and service for your model:

```dart
import 'package:sqflow_core/sqflow_core.dart';

// 1. Create table configuration
final usersTable = Table<User>(
  name: 'users',
  schema: '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      age INTEGER,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT  -- For soft delete
    )
  ''',
  fromJson: User.fromJson,
  paranoid: true,  // Enable soft deletes
  primaryKey: 'id',
);

// 2. Create database manager (provide tables list)
final dbManager = DB(databaseName: 'my_app.db', version: 1, tables: [usersTable]);
// Or auto-detect version from migrations:
final dbManager = DB.autoVersion(databaseName: 'my_app.db', tables: [usersTable]);

// 3. Create the service
final userService = SqflowCore<User>(
  dbManager: dbManager,
  table: usersTable,
);
```

### Step 4: Initialize and Use

In your `main.dart` or initialization function:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The database opens lazily on first use
  // Table schema will be automatically registered and created

  runApp(MyApp());
}
```

Now use CRUD operations:

```dart
// Insert a new user
final newUser = User(
  id: 'user_001',
  name: 'John',
  age: 30,
  isActive: true,
  createdAt: DateTime.now(),
);

await userService.insertAsync(newUser);

// Read by ID
final user = await userService.readAsync('user_001');
print(user?.name);  // 'John'

// Update
if (user != null) {
  final updatedUser = user.copyWith(name: 'John Updated');
  await userService.updateAsync(updatedUser);
}

// Soft delete (sets deleted_at)
await userService.deleteAsync('user_001');

// Query with filters and pagination
final results = await userService.readAll(
  where: WhereBuilder()
    .ilike('name', '%Joh%')
    .isTrue('is_active'),
  sort: SortBuilder()
    .asc('name')
    .desc('created_at'),
  limit: 10,
  offset: 0,
);

print('Found ${results.data.length} users out of ${results.count} total');
```

## 🏗️ Architecture Overview

SqFlow follows a layered architecture:

```dart
┌─────────────────┐     ┌─────────────────┐
│   Flutter UI    │     │  Annotations    │
└────────┬────────┘     └────────┬────────┘
         │                       │
┌────────▼────────┐     ┌────────▼────────┐
│ SqflowCore │◄────┤   Code Gen      │
└────────┬────────┘     └─────────────────┘
         │
┌────────▼────────┐     ┌─────────────────┐
│   WhereBuilder  │     │   SortBuilder   │
└────────┬────────┘     └─────────────────┘
         │
┌────────▼────────┐
│       DB        │
└─────────────────┘
```

1. **Database Layer** (`DB`) - Connection management
2. **Query Layer** (`WhereBuilder`, `SortBuilder`) - Safe query construction
3. **Service Layer** (`SqflowCore`) - Business logic and CRUD
4. **Model Layer** (`Model`) - Data contracts
5. **Code Generation** (Optional) - Auto-generated schemas from annotations

## 🧩 Core Components

### DB: Database Manager

The entry point for database lifecycle management.

```dart
final dbManager = DB(
  databaseName: 'app_database.db',  // Default
  version: 1,                       // For migrations
);

// Lazy initialization - opens on first use
final database = await dbManager.database;

// Close when done
await dbManager.close();
```

**Properties:**

- `databaseName`: File name for SQLite database
- `version`: Schema version for migrations

### Model: Base Model Interface

All data models must extend the `Model` abstract class:

```dart
abstract class Model {
  Object get id;
  Map<String, dynamic> toJson();
}
```

**Required:**

- `id` getter - Unique identifier (String, int, etc.)
- `toJson()` method - Serializes to database format

**Recommended:**

- `fromJson` factory - For deserialization
- Timestamp fields: `createdAt`, `updatedAt`, `deletedAt`
- `copyWith()` method - For immutable updates

### Table<T>: Table Configuration

Configuration object for database tables:

```dart
final usersTable = Table<User>(
  name: 'users',
  schema: 'CREATE TABLE users (...)',  // Full SQL
  fromJson: User.fromJson,             // Deserialization factory
  paranoid: true,                      // Enable soft deletes
  primaryKey: 'id',                    // Defaults to 'id'
);
```

**Parameters:**

- `name`: Table name
- `schema`: Complete CREATE TABLE SQL statement
- `fromJson`: Factory to create model from database row
- `paranoid`: Enable/disable soft deletes
- `primaryKey`: Name of primary key column (default: 'id')

#### Indexes & CHECK constraints

Define indexes to speed up queries and CHECK constraints to enforce simple domain rules at the database level.

- **Indexes:** Improve lookup performance for frequent WHERE, JOIN, and ORDER BY columns. Example: create an index on `email` for fast uniqueness checks and lookups.
- **CHECK constraints:** Enforce allowed values or simple validation (e.g., `gender IN ('M','F','Other')`). CHECK keeps invalid data out of the table and centralizes validation logic.

When designing your schema, add indexes for columns you filter or sort by often, and use `CHECK` for small, immutable domain rules. Both features are supported by the runtime and are included in the sample `users` table used in tests.

### SqflowCore<T>: Main CRUD Service

The core service providing all database operations.

#### Constructor

```dart
final service = SqflowCore<T>(
  dbManager: dbManager,
  table: tableConfig,
);
```

#### CRUD Operations

| Method                                | Description              | Returns                     |
| ------------------------------------- | ------------------------ | --------------------------- |
| `insertAsync(T item)`                 | Insert single record     | Future<int> (row ID)        |
| `updateAsync(T item)`                 | Update by primary key    | Future<int> (affected rows) |
| `upsertAsync(T item)`                 | Insert or replace        | Future<void>                |
| `readAsync(Object id, {withDeleted})` | Read by ID               | Future<T?>                  |
| `deleteAsync(Object id, {force})`     | Delete (soft if enabled) | Future<int>                 |
| `restoreAsync(Object id)`             | Restore soft-deleted     | Future<int>                 |

#### Batch Operations

| Method                            | Description  |
| --------------------------------- | ------------ |
| `insertBatchAsync(List<T>)`       | Bulk insert  |
| `updateBatchAsync(List<T>)`       | Bulk update  |
| `upsertBatchAsync(List<T>)`       | Bulk upsert  |
| `deleteBatchAsync(List<Object>)`  | Bulk delete  |
| `restoreBatchAsync(List<Object>)` | Bulk restore |

All batch operations run in transactions for atomicity.

#### Read Operations

| Method                                       | Description        | Returns                   |
| -------------------------------------------- | ------------------ | ------------------------- |
| `readAll({where, sort, limit, offset, ...})` | Paginated query    | `Future<DataAndCount<T>>` |
| `existsAsync(Object id)`                     | Check existence    | `Future<bool>`            |
| `transaction(Function)`                      | Run in transaction | `Future<R>`               |

**Example - Paginated Query:**

```dart
final result = await userService.readAll(
  limit: 20,
  offset: 0,
  where: WhereBuilder()
    .gt('age', 18)
    .isTrue('is_active'),
  sort: SortBuilder()
    .asc('name')
    .desc('created_at'),
  withDeleted: false,  // Exclude soft-deleted
);

// result.data - List<User> (paginated)
// result.count - Total matching records
```

#### Synchronous Wrappers

All async methods have synchronous fire-and-forget versions:

```dart
// Async
final id = await userService.insertAsync(user);

// Sync (fire-and-forget)
userService.insert(
  user,
  onSuccess: (id) => print('Inserted: $id'),
  onError: (error, stackTrace) => debugPrint('Error: $error'),
);
```

### 🔗 ORM Relationships

Sqflow provides a powerful yet simple way to handle relationships between models. Instead of writing complex JOINs, you can define relationships and use **Eager Loading** to fetch related data automatically.

#### Relationship Types

| Annotation   | Description              | Example                              |
| :----------- | :----------------------- | :----------------------------------- |
| `@HasMany`   | One-to-Many relationship | `User` has many `Posts`              |
| `@HasOne`    | One-to-One relationship  | `User` has one `Profile`             |
| `@BelongsTo` | Many-to-One relationship | `Post` belongs to a `User`           |
| `@Join`      | Alias for `BelongsTo`    | Semantic alternative for `BelongsTo` |

#### Eager Loading (Type-Safe)

Sqflow uses a fluent `Includable` API to fetch related data. This provides compile-time safety and IDE autocompletion.

```dart
// 1. Fetch by table name or/and model type (Recommended)
final user = await userService.readAsync('u1', include: [
  Includable.table('posts'),
  Includable.model<Profile>(),
]);

// 2. Fetch by model type (Backward compatibility)
final post = await postService.readAsync(1, include: [
  Includable.model<User>(),
]);
```

### 🚀 Automated Model Generation (New!)

Sqflow now supports automated generation of SQL schemas, `toJson`, `fromJson`, and relationship fields using `build_runner`.

#### 1. Setup

Add `sqflow_generator` and `build_runner` to your `dev_dependencies`:

```yaml
dev_dependencies:
  sqflow_generator:
    path: path/to/sqflow_generator
  build_runner: ^2.4.0
```

#### 2. Annotate your Model

Use `@Schema` and `with _$ClassNameMixin`.

```dart
import 'package:sqflow_core/sqflow_core.dart';

part 'user.sql.g.dart'; // Generated file

@Schema(
  tableName: 'users',
  relationships: [
    HasMany(model: Post, foreignKey: 'user_id'),
  ],
)
class User extends Model with _$UserMixin {
  @ID(type: TEXT())
  @override
  final String id;

  @Column(type: TEXT())
  final String name;

  // Relationship fields are now managed by the mixin for better immutability
  // List<Post> get posts => ... (from mixin)

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

#### 3. Run Build Runner

```bash
dart run build_runner build
```

The generator will automatically:

- Create the SQL `CREATE TABLE` statement.
- Generate `toJson()` (in the mixin).
- Generate `_$ClassNameFromJson(json)` helper.
- Generate relationship fields (like `user` for a `BelongsTo` field).
- Handle type-safe collection mapping for `HasMany`.

#### 💡 Key Rules for Relationships

To ensure relationships work correctly, keep these rules in mind:

1.  **Foreign Key Mapping**: The `foreignKey` parameter must match the **SQL column name** in the database.
    - If your Dart field is `userId` and you use `snake_case` (default), the `foreignKey` should be `'user_id'`.
    - In `fromJson`, you must read this ID using the same SQL column name: `userId: json['user_id']`.

2.  **JSON Key for Related Objects**: When using `include`, the related data is injected into the JSON map using the **`model` name** (table name) as the key.
    - `HasMany(model: 'posts', ...)` -> Data is in `json['posts']` as a `List`.
    - `HasOne(model: 'profiles', ...)` -> Data is in `json['profiles']` as a `Map`.

3.  **Data Types**:
    - `HasMany` always returns a `List` (empty if no matches).
    - `HasOne` and `BelongsTo` return a `Map?` (null if no match).

---

#### 1. Defining Relationships

Relationships can be defined in two ways:

##### A. In the `@Schema` annotation (Class-level)

Ideal for centralizing relationship logic or when you don't have a specific field for the related object.

```dart
@Schema(
  tableName: 'users',
  hasMany: [
    HasMany(
      model: 'posts',       // Target table name
      foreignKey: 'user_id', // Field in target table pointing to this model
      localKey: 'id',       // (Optional) Field in this model (default: 'id')
    ),
  ],
)
class User extends Model { ... }
```

##### B. Using field annotations (Field-level)

Recommended for better readability and integration with your model fields.

```dart
@Schema(tableName: 'posts')
class Post extends Model {
  @ID(type: INTEGER(), autoIncrement: true)
  final int id;

  @Column(type: TEXT())
  final String title;

  @Column(type: TEXT())
  final String userId;

  // Defines that this post belongs to a User
  @Join(model: 'users', foreignKey: 'user_id')
  final User? author;
}
```

---

#### 2. Handling Data in `fromJson`

When you include a relationship, Sqflow injects the related data into the JSON map before calling your `fromJson` factory. The key in the map will be the **model name** (table name) of the target.

```dart
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as String,
    name: json['name'] as String,
    // Relationships are injected as lists for HasMany,
    // or as a single Map for HasOne/BelongsTo.
    posts: json['posts'] != null
        ? (json['posts'] as List)
            .map((p) => Post.fromJson(p as Map<String, dynamic>))
            .toList()
        : const [],
  );
}
```

---

To fetch related data, use the `Includable` API in `readAsync` or `readAll`.

```dart
// 1. Fetch a single user with all their posts (Type-safe)
final user = await userService.readAsync('u1', include: [Includable.model<Post>()]);

// 2. Fetch a post with its author
final post = await postService.readAsync(1, include: [Includable.model<User>()]);
print(post?.user?.name);

// 3. Bulk fetch with relationships
final result = await userService.readAll(
  where: WhereBuilder().eq('city', 'New York'),
  include: [Includable.model<Post>()],
);
```

#### 🛠 Configuration Details

- **`model`**: The name of the related table (e.g., `'posts'`).
- **`foreignKey`**: The column that links the tables (e.g., `'user_id'`).
- **`localKey`**: The column in the current table used for matching. Defaults to `'id'`.

#### 🚀 Performance

Sqflow uses **Batch Loading** to resolve relationships. If you fetch 20 users with their posts, Sqflow will execute:

1. One query to fetch 20 users.
2. One query to fetch all posts for those 20 users (`WHERE user_id IN (...)`).
3. Automatic in-memory mapping to attach posts to correct users.

This avoids the "N+1 Query Problem" and keeps your app fast.

### WhereBuilder: Fluent Query Builder

Type-safe, SQL-injection protected WHERE clause builder.

#### Basic Comparisons

```dart
final where = WhereBuilder()
  .eq('status', 'active')      // status = ?
  .ne('role', 'admin')         // role != ?
  .gt('age', 18)               // age > ?
  .gte('score', 60)            // score >= ?
  .lt('quantity', 100)         // quantity < ?
  .lte('price', 50.0);         // price <= ?
```

#### Pattern Matching

```dart
.where
  .like('name', '%John%')      // name LIKE ?
  .notLike('email', '%spam%')  // email NOT LIKE ?
  .ilike('title', '%search%')  // LOWER(title) LIKE LOWER(?)
  .regexp('phone', '^[0-9]+$');// phone REGEXP ?
```

#### NULL and Range Checks

```dart
.where
  .isNull('deleted_at')        // deleted_at IS NULL
  .isNotNull('email')          // email IS NOT NULL
  .between('price', 10, 100)   // price BETWEEN ? AND ?
  .isTrue('is_active')         // is_active = 1
  .isFalse('is_banned');       // is_banned = 0
```

#### IN/NOT IN Conditions

```dart
.where
  .inList('status', ['active', 'pending'])  // status IN (?, ?)
  .notInList('id', [1, 2, 3]);              // id NOT IN (?, ?, ?)
```

#### Logical Groups (AND/OR)

```dart
.where
  .eq('type', 'user')
  .andGroup((group) {
    group
      .gt('age', 18)
      .lt('age', 65);
  })
  .orGroup((group) {
    group
      .eq('city', 'Sofia')
      .eq('city', 'Plovdiv');
  });
// Produces: type = ? AND (age > ? AND age < ?) AND (city = ? OR city = ?)
```

#### Date/Time Operations

```dart
.where
  .dateOnlyEq('created_at', DateTime(2024, 1, 15))  // DATE(created_at) = ?
  .dateOnlyBetween('date', start, end)              // DATE(date) BETWEEN ? AND ?
  .timeOnlyEq('start_time', DateTime(2024, 1, 1, 9, 0)); // TIME(start_time) = ?
```

#### Raw SQL (Escape Hatch)

```dart
.where.raw('LENGTH(name) > ?', [3]);  // LENGTH(name) > ?
```

#### String Functions (LENGTH, SUBSTR)

Convenience helpers for common string-based conditions. These produce parameterized SQL using `LENGTH(...)` and `SUBSTR(...)` and keep argument ordering safe.

Examples:

```dart
// LENGTH helpers
WhereBuilder().lengthEq('first_name', 5);        // LENGTH(first_name) = ?
WhereBuilder().lengthGt('nickname', 2);         // LENGTH(nickname) > ?

// SUBSTR helpers (start, length, value)
WhereBuilder().substrEq('last_name', 1, 1, 'S'); // SUBSTR(last_name, ?, ?) = ?
WhereBuilder().substrLike('email', 1, 3, '%@g'); // SUBSTR(email, ?, ?) LIKE ?
WhereBuilder().substrIlike('first_name', 1, 2, 'jo'); // LOWER(SUBSTR(first_name, ?, ?)) LIKE LOWER(?)

// Use them in readAll queries
final result = await service.readAll(
  where: WhereBuilder()
    .lengthGt('first_name', 4)
    .substrLike('email', 1, 3, '%@g'),
);
```

#### Utilities

```dart
// Deep copy a builder
final newWhere = where.copy();

// Check if a column has conditions
if (where.hasConditionOn('email')) {
  print('Filtering by email');
}

// Get args
print(where.args); // List of arguments
```

#### Factory Patterns

```dart
// Soft delete aware queries
final where = WhereBuilders.softDelete(
  paranoid: true,
  withDeleted: false,
  onlyDeleted: false,
);

// Multi-column search
final search = WhereBuilders.multiColumnSearch(
  'john',
  ['first_name', 'last_name', 'email'],
  caseSensitive: false,
);
```

### SortBuilder: Order By Builder

Simple fluent interface for ORDER BY clauses:

```dart
final sort = SortBuilder()
  .asc('last_name')      // last_name ASC
  .desc('created_at')    // created_at DESC
  .asc('first_name');    // first_name ASC

final orderBy = sort.build();  // "last_name ASC, created_at DESC, first_name ASC"
```

### DataAndCount<T>: Paginated Results

Wrapper returned by `readAll()`:

```dart
class DataAndCount<T> {
  final List<T> data;    // Paginated items
  final int count;       // Total matching records
}
```

**Usage:**

```dart
final result = await service.readAll(limit: 10, offset: 0);
print('Showing ${result.data.length} of ${result.count} total records');

// Pagination calculation
final totalPages = (result.count / 10).ceil();
```

## 🎯 Annotations & Code Generation

For a more declarative approach, use annotations with code generation.

**See [ANNOTATIONS.md](ANNOTATIONS.md) for full documentation.**

### 1. Add Dependencies

```yaml
dependencies:
  sqflow_core: ^latest

dev_dependencies:
  build_runner: ^latest

  sqflow_generator: ^latest
```

### 2. Create Annotated Model

**Note:** Import `package:sqflow_core/sqflow_core.dart` to access annotations.

```dart
import 'package:sqflow_core/sqflow_core.dart';

part 'user.sql.g.dart';  // Generated file

@Schema(
  tableName: 'users',
  paranoid: true,
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['first_name', 'last_name']),
  ],
  // Optional: control how Dart fields become SQL column names
  columnNaming: ColumnNamingStrategy.snakeCase, // or camelCase / pascalCase
)
class User extends Model {
  @ID(type: TEXT(), autoIncrement: false, unique: true)
  @override
  final String id;

  @Column(type: TEXT())
  final String firstName;

  @Column(type: TEXT())
  final String lastName;

  @Column(type: TEXT(), unique: true)
  final String email;

  @Column(type: INTEGER(), nullable: true)
  final int? age;

  @Column(type: INTEGER(), defaultValue: 1)
  final bool isActive;

  @Column(type: TEXT())
  final DateTime createdAt;

  @Column(type: TEXT(), nullable: true)
  final DateTime? updatedAt;

  @Column(type: TEXT(), nullable: true)
  final DateTime? deletedAt;

  // Constructor, toJson, fromJson, etc.

  // Auto-generated getter
  Table<User> get table => _$usersTable;
}
```

### 3. Generate Code

```bash
flutter pub run build_runner build
```

This generates:

- Complete SQL schema with indexes
- `Table<User>` configuration
- Column names generated per `columnNaming` strategy

### 4. Use Generated Table

```dart
// Use the auto-generated table
final userService = SqflowCore<User>(
  dbManager: dbManager,
  table: user.table,  // Generated getter
);
```

### Column Naming Strategy

Control column naming in generated SQL with `ColumnNamingStrategy`:

#### Available Strategies

| Strategy     | Example                        | Use Case                               |
| ------------ | ------------------------------ | -------------------------------------- |
| `snakeCase`  | `firstName` → `first_name`     | Default, recommended for SQL databases |
| `camelCase`  | `firstName` → `firstName`      | Match Dart naming conventions          |
| `pascalCase` | `firstName` → `FirstName`      | Some legacy systems require PascalCase |
| `custom`     | Requires explicit column names | Full control over SQL column names     |

#### snakeCase (Default)

```dart
@Schema(
  tableName: 'users',
  columnNaming: ColumnNamingStrategy.snakeCase,
)
class User extends Model {
  @Column(type: TEXT())
  final String firstName;  // SQL: first_name

  @Column(type: TEXT())
  final String lastName;   // SQL: last_name
}
```

#### camelCase

```dart
@Schema(
  tableName: 'users',
  columnNaming: ColumnNamingStrategy.camelCase,
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['firstName', 'lastName']), // Use camelCase in indexes
  ],
)
class User extends Model {
  @Column(type: TEXT())
  final String firstName;  // SQL: firstName
  @Column(type: TEXT())
  final String lastName;   // SQL: lastName
}
```

#### pascalCase

```dart
@Schema(
  tableName: 'users',
  columnNaming: ColumnNamingStrategy.pascalCase,
)
class User extends Model {
  @Column(type: TEXT())
  final String firstName;  // SQL: FirstName
  @Column(type: TEXT())
  final String lastName;   // SQL: LastName
}
```

#### Explicit Naming

Individual column names can be overridden regardless of the strategy:

```dart
@Schema(
  tableName: 'users',
  columnNaming: ColumnNamingStrategy.snakeCase,
)
class User extends Model {
  @Column(type: TEXT(), columnName: 'user_first_name')
  final String firstName;  // SQL: user_first_name

  @Column(type: TEXT(), columnName: 'user_last_name')
  final String lastName;   // SQL: user_last_name

  @ID(type: TEXT(), columnName: 'user_id')
  @override
  final String id;         // SQL: user_id
}
```

#### Best Practices

- Use the same strategy in `indexes` column lists as your actual SQL columns
- `WhereBuilder` and `SortBuilder` accept column names — match your SQL schema exactly
- For manual `Table<T>` schemas, naming is fully under your control; `columnNaming` applies only to generated models
- Choose one strategy per table and be consistent across all columns
  **Benefits:**
  - ✅ Auto-generated SQL schemas
  - ✅ Type safety for column names
  - ✅ Index configuration in annotations
  - ✅ Less boilerplate code
  - ✅ Compile-time schema validation

## 🔧 Advanced Usage

### Complex Queries

**Multi-condition search with pagination:**

```dart
Future<DataAndCount<User>> searchUsers({
  String? query,
  int? minAge,
  int? maxAge,
  List<String>? cities,
  bool? activeOnly,
  int page = 1,
  int perPage = 20,
}) async {
  final where = WhereBuilder();

  // Text search across multiple fields
  if (query != null && query.isNotEmpty) {
    where.andGroup((ag) {
      ag.ilike('first_name', '%$query%')
       .ilike('last_name', '%$query%')
       .ilike('email', '%$query%');
    });
  }

  // Age range
  if (minAge != null) where.gte('age', minAge);
  if (maxAge != null) where.lte('age', maxAge);

  // City filter
  if (cities != null && cities.isNotEmpty) {
    where.inList('city', cities);
  }

  // Active users only
  if (activeOnly == true) {
    where.isTrue('is_active');
  }

  // Execute query
  return await userService.readAll(
    where: where,
    sort: SortBuilder()
      .asc('last_name')
      .asc('first_name'),
    limit: perPage,
    offset: (page - 1) * perPage,
    withDeleted: false,
  );
}
```

### Transactions

Execute multiple operations atomically:

```dart
try {
  await userService.transaction((txn) async {
    // Transfer operations
    await userService.deleteAsync('user_001', force: true);
    await txn.delete('orders', where: 'user_id = ?', whereArgs: ['user_001']);
    await txn.delete('payments', where: 'user_id = ?', whereArgs: ['user_001']);

    // All or nothing - rolls back on any error
  });

  print('Transaction completed successfully');
} catch (e, stackTrace) {
  debugPrint('Transaction failed: $e');
  // All changes automatically rolled back
}
```

### Migrations

Use the fluent `MigrationBuilder` attached to each `Table` to define schema changes with target versions. The database applies pending migrations during `onCreate`/`onUpgrade` and tracks them in a dedicated migrations table.

```dart
// Define migrations for a table
final usersWithMigrations = usersTable
  .migrate()
  .addColumn(name: 'email', type: 'TEXT', version: 2, nullable: true)
  .createIndex(name: 'idx_users_email', columns: ['email'], version: 3, unique: false)
  .build();

// Provide the table with migrations to DB
final db = DB.autoVersion(databaseName: 'app.db', tables: [usersWithMigrations]);
```

**Migration Tips:**

- Always test migrations with real data
- Use transactions for multi-step migrations
- Consider backup before major changes
- Document all schema changes

### Testing

**Unit tests with in-memory database:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for desktop/tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('User insert and read', () async {
    final dbManager = DB(databaseName: inMemoryDatabasePath, version: 1);
    final service = SqflowCore<User>(...);

    // ... test logic
  });
}
```

## 📜 License

MIT License
