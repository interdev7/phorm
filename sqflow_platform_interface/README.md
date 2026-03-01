# sqflow_platform_interface

Annotation library for declarative SQL table and schema definitions in **Dart**.

`sqflow_platform_interface` is designed to work together with code generators (most notably [`sqflow_generator`](https://github.com/interdev7/sqflow_generator)) to produce:

- SQL `CREATE TABLE` schemas
- Index definitions
- Foreign keys
- Runtime table metadata (`TableSchema<T>`)

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
- Database-agnostic logical data types

---

## Installation

Add the dependency:

```yaml
dependencies:
  sqflow_annotations:
    git:
      url: https://github.com/interdev7/sqflow_annotations
```

Then add the generator:

```yaml
dev_dependencies:
  sqflow_generator:
    git:
      url: https://github.com/interdev7/sqflow_generator
  build_runner: ^2.4.0
```

---

## Basic Usage

### 1. Annotate your model

```dart
import 'package:sqflow_annotations/sqflow_annotations.dart';

part 'user.sql.g.dart';

@Schema(
  tableName: 'users',
  paranoid: true,
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['firstName', 'lastName']),
  ],
)
class User {
  @ID(type: DataTypes.TEXT)
  final String id;

  @Column(type: DataTypes.TEXT)
  final String firstName;

  @Column(type: DataTypes.TEXT)
  final String lastName;

  @Column(type: DataTypes.TEXT, unique: true)
  final String email;

  @Column(type: DataTypes.TEXT, nullable: true)
  final String? phone;

  @Column(
    type: DataTypes.TEXT,
    check: CHECK(['M', 'F', 'Other']),
  )
  final String gender;

  @Column(type: DataTypes.DATETIME)
  final DateTime createdAt;

  @Column(type: DataTypes.DATETIME, nullable: true)
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

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        gender: json['gender'],
        createdAt: DateTime.parse(json['createdAt']),
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'])
            : null,
      );
}
```

---

### 2. Run the generator

```bash
dart run build_runner build
```

This will generate a `.sql.g.dart` file containing the SQL schema and a `TableSchema<T>` instance.

---

## Generated Output (Example)

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  gender TEXT NOT NULL CHECK(gender IN ('M', 'F', 'Other')),
  created_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE UNIQUE INDEX users_email_idx ON users(email);
CREATE INDEX users_first_name_last_name_idx ON users(first_name, last_name);
```

And a runtime schema object:

```dart
final usersTableSchema = _UserTableSchema(
  tableSchema: _usersSchema,
  tableName: 'users',
  fromJson: User.fromJson,
);
```

---

## Annotations

### `@Schema`

Defines table-level configuration.

```dart
@Schema(
  tableName: 'users',
  paranoid: true,
  indexes: [Index(columns: ['email'], unique: true)],
)
```

| Property    | Type          | Description                        |
| ----------- | ------------- | ---------------------------------- |
| `tableName` | `String?`     | Explicit table name                |
| `indexes`   | `List<Index>` | Table indexes                      |
| `paranoid`  | `bool`        | Enables soft deletes (`deletedAt`) |

---

### `@Column`

Standard column definition.

```dart
@Column(
  type: DataTypes.TEXT,
  nullable: false,
  unique: false,
  defaultValue: 'N/A',
  check: CHECK(['A', 'B']),
)
```

Supported options:

- `type` (required)
- `nullable`
- `unique`
- `defaultValue`
- `length`
- `precision`
- `scale`
- `check`

---

### `@ID`

Primary key column.

```dart
@ID(
  type: DataTypes.INTEGER,
  autoIncrement: true,
)
```

- Always `NOT NULL`
- Automatically marked as `PRIMARY KEY`

---

### `@ForeignKey`

Defines a foreign key relationship.

```dart
@ForeignKey(
  type: DataTypes.INTEGER,
  referencesTable: 'users',
  referencesColumn: 'id',
  onDelete: 'CASCADE',
)
```

---

## SQLite Type Mapping

`sqflow_annotations` uses **logical data types**, which are mapped by `sqflow_generator` to concrete SQLite types.

SQLite uses dynamic typing, so the mapping is pragmatic and predictable.

| DataTypes      | SQLite Type            | Notes                                  |
| -------------- | ---------------------- | -------------------------------------- |
| `INTEGER`      | `INTEGER`              | Used for ids, counters                 |
| `BIGINT`       | `INTEGER`              | SQLite stores 64-bit ints              |
| `REAL`         | `REAL`                 | Floating point                         |
| `TEXT`         | `TEXT`                 | Arbitrary length string                |
| `VARCHAR(n)`   | `VARCHAR(n)` or `TEXT` | Falls back to `TEXT` if length omitted |
| `CHAR(n)`      | `CHAR(n)`              | Defaults to `CHAR(1)`                  |
| `DECIMAL(p,s)` | `DECIMAL(p,s)`         | Stored as numeric/text internally      |
| `BOOLEAN`      | `INTEGER`              | `1` = true, `0` = false                |
| `DATE`         | `TEXT`                 | ISO-8601 recommended                   |
| `DATETIME`     | `TEXT`                 | ISO-8601 recommended                   |
| `TIME`         | `TEXT`                 | ISO-8601 recommended                   |
| `BLOB`         | `BLOB`                 | Binary data                            |
| `JSON`         | `TEXT`                 | No native JSON in SQLite               |

> ⚠️ SQLite does **not** enforce strict column types. Validation is mostly application-level.

---

## DataTypes

Logical column types (database-agnostic):

- `INTEGER`
- `BIGINT`
- `REAL`
- `TEXT`
- `VARCHAR`
- `CHAR`
- `DECIMAL`
- `BOOLEAN`
- `DATE`
- `DATETIME`
- `TIME`
- `BLOB`
- `JSON`

The generator maps these to concrete SQL types (e.g. SQLite, PostgreSQL).

---

## Gotchas & Limitations

### 1. SQLite is weakly typed

- SQLite does **not** strictly enforce column types
- `VARCHAR`, `CHAR`, `DECIMAL` are mostly semantic
- Validation should be done at the application layer

---

### 2. BOOLEAN is stored as INTEGER

```dart
@Column(type: DataTypes.BOOLEAN, defaultValue: true)
final bool isActive;
```

Generated SQL:

```sql
is_active INTEGER NOT NULL DEFAULT 1
```

You must convert manually in `toJson` / `fromJson`.

---

### 3. CHECK constraints are limited

- `CHECK` works in SQLite
- But complex expressions are discouraged
- Prefer enums / validation in Dart

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

Indexes must use **SQL column names**, not Dart field names.

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
│ TableSchema  │
│ Runtime Meta │
└──────────────┘
```

---

## pub.dev Style Notes

- Small, focused README
- Clear examples
- No excessive implementation details
- Generator responsibility clearly separated

---

## FAQ

### Why is `DateTime` stored as `TEXT`?

SQLite does not have a native `DATE` or `DATETIME` type.

Storing dates as `TEXT` (ISO-8601) is the **recommended SQLite approach**:

```text
2024-01-31T18:42:00.000Z
```

**Benefits:**

- Human-readable
- Lexicographically sortable
- Timezone-safe when using UTC
- Compatible with SQLite date functions

Alternative formats (INTEGER timestamps) are possible, but `TEXT` is the safest and most portable default.

---

### Why is `BOOLEAN` mapped to `INTEGER`?

SQLite has no real boolean type.

Instead, booleans are represented as:

- `1` → `true`
- `0` → `false`

Generated SQL:

```sql
is_active INTEGER NOT NULL DEFAULT 1
```

In Dart, conversion is explicit:

```dart
isActive: json['isActive'] == 1 || json['isActive'] == true
```

This avoids ambiguity and matches SQLite best practices.

---

### Why are `VARCHAR` and `CHAR` treated like `TEXT`?

SQLite does **not enforce length constraints**.

- `VARCHAR(255)`
- `CHAR(10)`
- `TEXT`

All behave identically at runtime.

Length is preserved **for semantic clarity** and future compatibility with stricter databases.

---

### Why are there no migrations?

`sqflow_generator` is intentionally **schema-only**.

- No diffing
- No ALTER TABLE
- No version tracking

This keeps the system:

- Predictable
- Simple
- Easy to reason about

Migration tools can be layered on top if needed.

---

## Related Packages

- **sqflow_generator** – SQL schema code generator
  [https://github.com/interdev7/sqflow_generator](https://github.com/interdev7/sqflow_generator)

- **sqflow_core** – Runtime database layer (optional)

---

## Status

- Dart SDK: `>=3.0.0 <4.0.0`
- Version: **1.0.0**
- Not published to pub.dev (`publish_to: none`)

---

## License

MIT (or specify your license here)
