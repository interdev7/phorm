# Annotations

Annotation library for declarative SQL table and schema definitions in **Dart**, integrated directly into `sqflow_core`.

These annotations are designed to work together with code generators (most notably [`sqflow_generator`](https://github.com/interdev7/sqflow_generator)) to produce:

- SQL `CREATE TABLE` schemas
- Index definitions
- Foreign keys
- Runtime table configuration (`Table<T>`)

The library itself **does not generate SQL** — it only provides annotations and base classes that generators can understand.

---

## Features

- Declarative table definitions via annotations
- Strongly-typed column definitions
- Primary keys & foreign keys
- Indexes (unique & non-unique)
- CHECK constraints
- Default values
- Soft delete ("paranoid") support
- Native SQLite data types

---

## Installation

Add the dependency:

```yaml
dependencies:
  sqflow_core: ^latest
```

Then add the generator:

```yaml
dev_dependencies:
  sqflow_generator: ^latest
  build_runner: ^latest
```

---

## Basic Usage

### 1. Annotate your model

**Import `package:sqflow_core/sqflow_core.dart`** — annotations are integrated directly into the package.

```dart
import 'package:sqflow_core/sqflow_core.dart';

part 'user.sql.g.dart';

@Schema(
  tableName: 'users',
  paranoid: true,
  indexes: [
    Index(columns: ['email'], unique: true),
    // IMPORTANT: use column names consistent with your naming strategy
    Index(columns: ['first_name', 'last_name']),
  ],
)
class User extends Model with _$SQFlowUserMixin {
  @ID()
  @override
  final String id;

  @Column()
  final String firstName;

  @Column()
  final String lastName;

  @Column(unique: true)
  final String email;

  @Column(nullable: true)
  final String? phone;

  @Column(
    validators: [ContainsValidator(['M', 'F', 'Other'])],
  )
  final String gender;

  @Column()
  final DateTime createdAt;

  @Column(nullable: true)
  final DateTime? deletedAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.gender,
    required this.createdAt,
    this.deletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}
```

---

### `@Schema`

Defines table-level configuration.

```dart
@Schema(
  tableName: 'users',
  paranoid: true,
  indexes: [Index(columns: ['email'], unique: true)],
  // Optional: column naming strategy
  columnNaming: ColumnNamingStrategy.snakeCase,
)
```

| Property        | Type                   | Description                                 |
| --------------- | ---------------------- | ------------------------------------------- |
| `tableName`     | `String?`              | Explicit table name                         |
| `indexes`       | `List<Index>`          | Table indexes                               |
| `paranoid`      | `bool`                 | Enables soft delete (`deletedAt`)           |
| `columnNaming`  | `ColumnNamingStrategy` | Column naming strategy (snake/camel/pascal) |
| `relationships` | `List<Relationship>`   | `HasMany`, `HasOne`, `BelongsTo`            |

---

### `@Column`

Standard column definition.

```dart
@Column(
  nullable: false,
  unique: false,
  defaultValue: 'N/A',
  validators: [ContainsValidator(['A', 'B'])],
)
```

Supported options:

- `sqlType` (override)
- `columnName` (override)
- `nullable`
- `unique`
- `defaultValue`
- `validators`

---

### `@ID`

Primary key column.

```dart
@ID(
  autoIncrement: true,
)
```

- Always `NOT NULL`
- Automatically marked as `PRIMARY KEY`

---

## 🔗 Relationship Annotations

These annotations define ORM-style relationships for **Eager Loading**. They can be used inside `@Schema` or directly on class fields.

#### `@HasMany`

Defines a one-to-many relationship.

```dart
@HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id')
// or
// @HasMany(model: Post, foreignKey: 'user_id') // localKey is inferred
final List<Post> posts;
```

#### `@HasOne`

Defines a one-to-one relationship.

```dart
@HasOne(model: Profile, foreignKey: 'user_id')
final Profile? profile;
```

#### `@BelongsTo`

Defines a many-to-one relationship.

```dart
@BelongsTo(model: User, foreignKey: 'user_id')
final User? author;
```

#### `@Join`

A semantic alias for `@BelongsTo`.

```dart
@Join(model: 'users', foreignKey: 'user_id')
final User? user;
```

| Property     | Type     | Description                                |
| ------------ | -------- | ------------------------------------------ |
| `model`      | `String` | Target table name                          |
| `foreignKey` | `String` | Field in the related table (or this table) |
| `localKey`   | `String` | Field in this table (or related table)     |

---

## SQLite Type Mapping

SQFlow automatically infers the SQLite data type from your Dart field types.

| Dart Type   | SQLite Type | Notes                              |
| :---------- | :---------- | :--------------------------------- |
| `String`    | `TEXT`      | Default for strings, UUIDs         |
| `int`       | `INTEGER`   | Standard integer                   |
| `bool`      | `INTEGER`   | Stored as `1` (true) / `0` (false) |
| `double`    | `REAL`      | Floating point numbers             |
| `num`       | `NUMERIC`   | Supports both int and double       |
| `DateTime`  | `TEXT`      | Stored as ISO-8601 strings         |
| `Uint8List` | `BLOB`      | Binary data                        |

> [!NOTE]
> For booleans and dates, the generator handles conversion between Dart types and SQLite representations automatically.

---

## Gotchas & Limitations

### 1. SQLite is weakly typed

SQLite does **not** strictly enforce column types. Validation should be done at the application layer.

### 2. BOOLEAN is stored as INTEGER

```dart
@Column(defaultValue: 1)
final bool isActive;
```

Generated SQL:

```sql
is_active INTEGER NOT NULL DEFAULT 1
```

You must convert manually in `toJson` / `fromJson`.

---

### 3. Validation should be done in Dart

- `CHECK` constraints are supported via `ICheckValidator`
- But complex logic is better handled in Dart via `IJsonValidator`

---

### 4. Paranoid mode requires `deletedAt`

If `@Schema(paranoid: true)` is set:

- A `deletedAt` field **must exist**
- Name must resolve to `deleted_at`
- Otherwise generation will fail

---

### 5. Field names are auto-converted

- Dart: `camelCase`
- SQL: `snake_case`

```dart
firstName → first_name
createdAt → created_at
```

Indexes must use **SQL column names** (snake_case), not Dart field names.

---

### 6. No migrations

`sqflow_generator` generates **full CREATE TABLE schemas**.

- No ALTER TABLE
- No diff-based migrations

This is intentional and keeps the generator simple.

---

## Soft Deletes (Paranoid Mode)

When `paranoid: true`:

- The model **must** define a `deletedAt` field
- Records are marked as deleted instead of being removed
- The generator automatically detects soft-delete support

---

## Build Flow (Annotations → SQL)

```text
┌──────────────┐
│ Dart Model   │
│ + Annotations│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ sqflow_      │
│ generator    │
│ (build_runner)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Generated    │
│ .sql.g.dart  │
│ SQL Schema   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Table<T>     │
│ Runtime Meta │
└──────────────┘
```

---

## Column Naming Strategy

`ColumnNamingStrategy` controls how Dart field names are mapped to SQL column names by the generator.

```dart
@Schema(
  tableName: 'users',
  paranoid: true,
  columnNaming: ColumnNamingStrategy.camelCase,
  indexes: [
    Index(columns: ['email'], unique: true),
    // matches camelCase strategy
    Index(columns: ['firstName', 'lastName']),
  ],
)
class User {
  @ID()
  final String id;

  @Column()
  final String firstName;

  @Column()
  final String lastName;
  // ...
}
```

Generated SQL (camelCase example):

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  createdAt TEXT NOT NULL,
  deletedAt TEXT
);

CREATE UNIQUE INDEX users_email_idx ON users(email);
CREATE INDEX users_firstName_lastName_idx ON users(firstName, lastName);
```

Notes:

- Choose `snakeCase`, `camelCase`, or `pascalCase` to fit your conventions.
- Ensure `indexes` reference column names consistent with the chosen strategy.
- When writing manual SQL or using `Table<T>` without code generation, you fully control column names in `schema`; set `columnNaming` only for generated models.

```

---

## Related Packages

* **sqflow_generator** – SQL schema code generator
  [https://github.com/interdev7/sqflow_generator](https://github.com/interdev7/sqflow_generator)
```
