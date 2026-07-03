# PHORM Annotations 🚀

[![Pub Version](https://img.shields.io/pub/v/phorm_annotations.svg)](https://pub.dev/packages/phorm_annotations)
[![Build Status](https://github.com/interdev7/phorm/actions/workflows/main.yml/badge.svg)](https://github.com/interdev7/phorm/actions)
[![Coverage](https://codecov.io/gh/interdev7/phorm/branch/main/graph/badge.svg?flag=phorm_annotations)](https://codecov.io/gh/interdev7/phorm?flags[0]=phorm_annotations)
[![GitHub Stars](https://img.shields.io/github/stars/interdev7/phorm.svg?style=flat&logo=github)](https://github.com/interdev7/phorm)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.5.0-blue?logo=dart)](https://dart.dev)

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
| `dialect`       | `SqlDialectKind`       | Target SQL dialect for DDL generation (`sqlite` (default), `postgres`, `mysql`). |
| `relationships` | `List<Relationship>`   | Define `HasMany`, `HasOne`, or `BelongsTo`.                                 |
| `timestamps`    | `bool`                 | Auto-manage `createdAt` / `updatedAt` (default `true`).                     |
| `useToJson`     | `bool`                 | Generate the `toJson()` mapper (default `true`).                            |
| `useFromJson`   | `bool`                 | Generate the `fromJson()` factory (default `true`).                         |
| `useCopyWith`   | `bool`                 | Generate the `copyWith()` helper (default `true`).                          |
| `useToString`   | `bool`                 | Generate the `toString()` helper (default `true`).                          |
| `useValidator`  | `bool`                 | Generate the `validate()` method from column `CHECK` constraints (default `true`). |
| `generateFullService` | `bool`           | Generate the pluralized static service class (e.g. `Users`) exposing the full CRUD/query API and column constants. Set `false` to emit only the lightweight schema/table/mappers and skip the large service (default `true`). |

#### Using a model with `generateFullService: false`

Without the generated `Users` facade you still get `usersTable`,
`fromJson`/`toJson` and `copyWith` — do CRUD via a `PhormCore<T>` from the DB:

```dart
@Schema(tableName: 'users', generateFullService: false)
class User extends Model with _$PhormUserMixin { /* ... */ }

// Register the generated table, then resolve a service for the model:
final db = DB(databaseName: 'app.db', version: 1, tables: [usersTable]);
final users = db.service<User>(); // PhormCore<User>

await users.insert(User(id: 1, email: 'a@b.c'));
final page = await users.readAll(limit: 20);

// No column constants → use a typed PhormColumn or a WhereBuilder string:
const email = PhormColumn<String>('email');
final admins = await users.where(email.like('%@admin.com')).get();
```

### `@Column`

Standard column definition. PHORM automatically infers the SQLite type from the Dart field type.

```dart
@Column(unique: true, defaultValue: 'active')
final String status;
```

| Property       | Type                | Description                                                    |
| :------------- | :------------------ | :------------------------------------------------------------- |
| `columnName`   | `String?`           | Override column name.                                          |
| `sqlType`      | `String?`           | Explicit SQL type override as a raw string (e.g. `'VARCHAR(255)'`). |
| `type`         | `SqlType?`          | Explicit SQL type as a typed object (e.g. `VARCHAR(255)`, `DECIMAL(10, 2)`, `JSONB()`). |
| `unique`       | `bool`              | Enforce `UNIQUE` constraint.                                   |
| `nullable`     | `bool`              | Mark column as `NULL` or `NOT NULL`.                           |
| `defaultValue` | `dynamic`           | SQL `DEFAULT` value.                                           |
| `validators`   | `List<IValidator>?` | List of validators (triggers SQL `CHECK` and Dart validation). |
| `converter`    | `ValueConverter?`   | Custom Dart ↔ SQL value transformer.                          |
| `collate`      | `String?`           | Specify string collation (e.g. `Collate.noCase`).              |

`SqlType` objects are organised by dialect: `common_types` (`VARCHAR`, `TEXT`, `INTEGER`, `BIGINT`, `BOOLEAN`, `REAL`, `DOUBLE`, `DECIMAL`, `DATE`, `TIME`, `TIMESTAMP`, `BLOB`, `JSON`), `sqlite_types` (`NUMERIC`, `Collate`), `postgres_types` (`JSONB`), `mysql_types` (scaffolded). Resolution precedence: `sqlType` → `type` → `converter` → inferred Dart type.

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

## SQL Types

A column's SQL type is resolved in this order of preference:

1. **Inferred** from the Dart field type — the default (see [Automatic Type Mapping](#automatic-type-mapping)).
2. **Typed override** — `@Column(type: ...)` with a `SqlType` object (`TEXT()`, `VARCHAR(255)`, `DECIMAL(10, 2)`, `JSONB()`). Compile-time checked; **preferred**.
3. **Raw override** — `@Column(sqlType: '...')` for DDL that no `SqlType` class covers.
4. **Converter** — `@Column(converter: ...)` to store complex Dart objects (`Map`, `List`, enums, domain types).

```dart
@Column(type: VARCHAR(255))
final String title;

@Column(sqlType: 'INTEGER CHECK (age >= 0)')
final int age;
```

In **migrations**, `addColumn` takes a plain type string:

```dart
table.migrate().addColumn(name: 'age', type: 'INTEGER', version: 2);
```

> [!NOTE]
> The older `SqlTypes` string-constant class (`SqlTypes.text`, …) is
> **deprecated** — use `type:` (typed `SqlType`), a raw `sqlType:` string, or a
> plain type string in migrations instead.

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
      createPivot: true,      // auto-create the pivot table (default: false)
      pivotForeignKeys: true, // add FK ... ON DELETE CASCADE (needs createPivot)
    ),
  ],
)
class User extends Model with _$PhormUserMixin { ... }
```

> **Pivot tables**: by default the pivot (join) table for a `ManyToMany` must be
> created manually. Set `createPivot: true` to let `phorm_generator` emit a
> `CREATE TABLE IF NOT EXISTS <pivot>` automatically, and `pivotForeignKeys: true`
> to also generate `FOREIGN KEY ... ON DELETE CASCADE` constraints for both
> columns. Both default to `false`, so existing schemas are unaffected.

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
