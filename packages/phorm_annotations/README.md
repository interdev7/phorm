# PHORM Annotations 🚀

Annotation library for declarative SQL table and schema definitions in **Dart**.

`phorm_annotations` provides the building blocks for defining your database schema using standard Dart classes. It is designed to work with [`phorm_generator`](https://github.com/interdev7/phorm_generator) to automate SQL generation and runtime metadata.

---

## Features

- **Declarative Schemas**: Define tables and columns using `@Schema`, `@Column`, and `@ID`.
- **Relationships**: Annotations for `HasMany`, `BelongsTo`, `HasOne`, and `ManyToMany` (with pivot tables).
- **Type Safety**: Database-agnostic logical types mapped to SQLite.
- **Constraints**: Support for `UNIQUE`, `CHECK`, and `DEFAULT` values.
- **Paranoid Mode**: Built-in support for soft deletes via `deletedAt`.
- **Factories**: `Factory<T>` interface for generating test/seed data.
- **Value Converters**: `ValueConverter<D, S>` for custom Dart ↔ SQL type transformations.

---

## Basic Usage

### 1. Annotate your model

```dart
import 'package:phorm_annotations/phorm_annotations.dart';

part 'user.sql.g.dart';

@Schema(
  tableName: 'users',
  paranoid: true,
  columnNaming: ColumnNamingStrategy.snakeCase,
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['first_name', 'last_name']),
  ],
)
class User extends Model with _$PhormUserMixin {
  @ID(autoIncrement: false, unique: true)
  @override
  final String id;

  @Column()
  final String firstName;

  @Column()
  final String lastName;

  @Column(unique: true)
  final String email;

  @Column(
    validators: [
      ContainsValidator(['M', 'F', 'Other'], constraint: 'gender_check'),
    ],
  )
  final String gender;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$PhormUserFromJson(json);
}
```

### 2. Run the generator

```bash
dart run build_runner build
```

---

## Annotations Reference

### `@Schema`

Defines table-level configuration.

| Property        | Type                   | Description                                                                 |
| :-------------- | :--------------------- | :-------------------------------------------------------------------------- |
| `tableName`     | `String?`              | Explicit SQL table name.                                                    |
| `indexes`       | `List<Index>`          | List of table indexes.                                                      |
| `paranoid`      | `bool`                 | Enables soft deletes (requires `deletedAt` column).                         |
| `columnNaming`  | `ColumnNamingStrategy` | Strategy for mapping field names to SQL (snakeCase, camelCase, pascalCase). |
| `relationships` | `List<Relationship>`   | Define `HasMany`, `HasOne`, or `BelongsTo`.                                 |

### `@Column`

Standard column definition. PHORM automatically infers the SQLite type from the Dart field type.

```dart
@Column(unique: true, defaultValue: 'active')
final String status;
```

| Property       | Type                | Description                                                    |
| :------------- | :------------------ | :------------------------------------------------------------- |
| `columnName`   | `String?`           | Override column name.                                          |
| `unique`       | `bool`              | Enforce `UNIQUE` constraint.                                   |
| `nullable`     | `bool`              | Mark column as `NULL` or `NOT NULL`.                           |
| `defaultValue` | `dynamic`           | SQL `DEFAULT` value.                                           |
| `validators`   | `List<IValidator>?` | List of validators (triggers SQL `CHECK` and Dart validation). |
| `collate`      | `String?`           | Specify string collation (e.g. `Collate.noCase`).              |

---

## Automatic Type Mapping

PHORM maps Dart types to SQLite types automatically:

| Dart Type   | SQLite Type | Notes                              |
| :---------- | :---------- | :--------------------------------- |
| `String`    | `TEXT`      | Default for strings, UUIDs         |
| `int`       | `INTEGER`   | Standard integer                   |
| `bool`      | `INTEGER`   | Stored as `1` (true) / `0` (false) |
| `double`    | `REAL`      | Floating point numbers             |
| `num`       | `NUMERIC`   | Supports both int and double       |
| `DateTime`  | `TEXT`      | Stored as ISO-8601 strings         |
| `Uint8List` | `BLOB`      | Binary data                        |

---

## Standard SQL Types

For manual overrides in `@Column(sqlType: ...)` or when adding columns in migrations, use the **`SqlTypes`** class to avoid hardcoding strings:

```dart
// In a migration
table.addColumn(name: 'age', type: SqlTypes.integer, version: 2);

// In a model
@Column(collate: Collate.noCase)
final String username;
```

Available types: `SqlTypes.text`, `SqlTypes.integer`, `SqlTypes.real`, `SqlTypes.blob`, `SqlTypes.numeric`.

---

## Referential Actions

When defining relationships, use **`ReferentialAction`** for `onDelete` and `onUpdate` parameters:

```dart
HasMany(
  model: Order,
  foreignKey: 'user_id',
  onDelete: ReferentialAction.cascade,
);
```

Available actions: `cascade`, `setNull`, `setDefault`, `restrict`, `noAction`.

---

## 🔗 Relationships

Relationships define how models connect. They are used by `phorm` for automatic Eager Loading.

- **`HasMany`**: One-to-Many (e.g., User has many Posts).
- **`HasOne`**: One-to-One (e.g., User has one Profile).
- **`BelongsTo`**: Many-to-One (e.g., Post belongs to User).

```dart
@Schema(
  tableName: 'users',
  relationships: [
    HasMany(model: Post, foreignKey: 'user_id'),
    ManyToMany(
      model: Role,
      pivotTable: 'user_roles',
      foreignKey: 'user_id',
      relatedKey: 'role_id',
    ),
  ],
)
class User extends Model with _$PhormUserMixin { ... }
```

---

## Query Results

`phorm` provides two read methods with explicit return types:

| Method                  | Returns              | Use when                                     |
| :---------------------- | :------------------- | :------------------------------------------- |
| `readAll(...)`          | `Result<T>`          | You only need the list of records            |
| `readAllWithCount(...)` | `ResultWithCount<T>` | You need the list + total count (pagination) |

```dart
// Simple read — no cast needed
final result = await userService.readAll(limit: 20);
for (final user in result.data) { ... }

// With count — no cast needed
final paged = await userService.readAllWithCount(limit: 20, offset: 40);
print('Page 3: ${paged.data.length} of ${paged.count} total');
```

---

## Factories

Use the `Factory<T>` interface to generate model instances for testing or seeding:

```dart
class UserFactory extends Factory<User> {
  int _i = 0;

  @override
  User create() {
    _i++;
    return User(id: 'user_$_i', name: 'User $_i', email: 'user$_i@example.com');
  }
}

final users = UserFactory().createMany(50); // List<User>
```

---

## Status

- Dart SDK: `>=3.0.0 <4.0.0`
- License: MIT License
