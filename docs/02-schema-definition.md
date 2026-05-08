# Schema Definition

All schema configuration is done via annotations from `sqflow_platform_interface`. The `sqflow_generator` reads these annotations and generates the SQL schema, mixins, and serialization helpers.

---

## `@Schema`

Defines table-level configuration for a class.

```dart
@Schema(
  tableName: 'users',         // Optional. Defaults to class name in snakeCase
  paranoid: true,             // Enable soft deletes (requires deleted_at column)
  timestamps: true,           // Auto-inject created_at / updated_at (default: true)
  columnNaming: ColumnNamingStrategy.snakeCase, // default
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['first_name', 'last_name']),
  ],
  relationships: [
    HasMany(model: Post, foreignKey: 'user_id'),
    HasOne(model: Profile, foreignKey: 'user_id'),
  ],
  useToJson: true,    // Generate _$SQFlowClassToJson() (default: true)
  useFromJson: true,  // Generate _$SQFlowClassFromJson() (default: true)
  useCopyWith: true,  // Generate copyWith() (default: true)
)
class User extends Model with _$SQFlowUserMixin { ... }
```

### `@Schema` Parameters

| Parameter       | Type                   | Default     | Description                      |
| :-------------- | :--------------------- | :---------- | :------------------------------- |
| `tableName`     | `String?`              | class name  | Explicit SQL table name          |
| `paranoid`      | `bool`                 | `false`     | Soft delete support              |
| `timestamps`    | `bool`                 | `true`      | Auto `created_at`/`updated_at`   |
| `columnNaming`  | `ColumnNamingStrategy` | `snakeCase` | Field → column mapping strategy  |
| `indexes`       | `List<Index>`          | `[]`        | Table indexes                    |
| `relationships` | `List<Relationship>`   | `[]`        | `HasMany`, `HasOne`, `BelongsTo` |
| `useToJson`     | `bool`                 | `true`      | Generate toJson mixin            |
| `useFromJson`   | `bool`                 | `true`      | Generate fromJson helper         |
| `useCopyWith`   | `bool`                 | `true`      | Generate copyWith method         |

### Column Naming Strategies

| Strategy              | Dart field  | SQL column   |
| :-------------------- | :---------- | :----------- |
| `snakeCase` (default) | `firstName` | `first_name` |
| `camelCase`           | `firstName` | `firstName`  |
| `pascalCase`          | `firstName` | `FirstName`  |

---

## `@ID`

Marks a field as the primary key. Always `NOT NULL`.

```dart
@ID(autoIncrement: false)
@override
final String id;

// Integer auto-increment PK (sqlType inferred as INTEGER)
@ID(autoIncrement: true)
@override
final int id;
```

### `@ID` Parameters

| Parameter       | Type      | Default  | Description                   |
| :-------------- | :-------- | :------- | :---------------------------- |
| `sqlType`       | `String?` | inferred | Explicit SQLite type override |
| `autoIncrement` | `bool`    | `false`  | Auto-increment (for `int` PK) |
| `unique`        | `bool`    | `true`   | Enforce uniqueness            |
| `columnName`    | `String?` | `null`   | Override column name          |

> [!WARNING]
> `autoIncrement: true` only works with `int` fields (mapped to `INTEGER`). For string UUIDs, use `autoIncrement: false` (default).

---

## `@Column`

Defines a regular column.

```dart
@Column()
final String firstName;

@Column(unique: true)
final String email;

@Column(nullable: true)
final int? age;

@Column(defaultValue: true)
final bool isActive;

@Column(
  validators: [
    ContainsValidator(['M', 'F', 'Other'], constraint: 'gender_check'),
  ],
)
final String gender;

// Explicit column name (overrides naming strategy)
@Column(columnName: 'user_city')
final String city;

// Explicit SQL type override
@Column(sqlType: 'VARCHAR(255)')
final String bio;
```

| Parameter      | Type                | Default  | Description                          |
| :------------- | :------------------ | :------- | :----------------------------------- |
| `sqlType`      | `String?`           | inferred | Explicit SQLite type override        |
| `columnName`   | `String?`           | `null`   | Override column name                 |
| `unique`       | `bool`              | `false`  | `UNIQUE` constraint                  |
| `defaultValue` | `dynamic`           | `null`   | SQL `DEFAULT` value                  |
| `validators`   | `List<IValidator>?` | `null`   | Value constraints (Check/Regex/etc.) |

---

## Data Types

SQFlow automatically infers the SQLite data type from your Dart field types. You generally do not need to specify `sqlType` manually.

### Automatic Mapping

| Dart Type   | SQLite Type | Notes                              |
| :---------- | :---------- | :--------------------------------- |
| `String`    | `TEXT`      | Default for strings, UUIDs         |
| `int`       | `INTEGER`   | Standard integer                   |
| `bool`      | `INTEGER`   | Stored as `1` (true) / `0` (false) |
| `double`    | `REAL`      | Floating point numbers             |
| `num`       | `NUMERIC`   | Supports both int and double       |
| `DateTime`  | `TEXT`      | Stored as ISO-8601 strings         |
| `Uint8List` | `BLOB`      | Binary data                        |

### Manual Override

Use `sqlType` if you need a specific SQLite type definition:

```dart
@Column(sqlType: 'TEXT COLLATE NOCASE')
final String username;

@Column(sqlType: 'VARCHAR(100)')
final String shortBio;
```

> [!NOTE]
> For booleans and dates, the generator handles conversion between Dart types and SQLite representations automatically.

---

## Validators

Validators allow you to enforce data integrity both in SQLite (via `CHECK` constraints) and in Dart (via `toJson()` validation).

```dart
@Column(
  validators: [
    ContainsValidator(['active', 'inactive', 'pending']),
    NotEmptyValidator(),
  ],
)
final String status;
```

For a full list of available validators and details on how they work, see the [Validators](file:///Users/interdev7/Documents/sqflow/docs/10-validators.md) documentation.

---

## Indexes

Indexes dramatically speed up query performance on frequently filtered columns.

```dart
@Schema(
  tableName: 'users',
  indexes: [
    Index(columns: ['email'], unique: true),          // Unique index
    Index(columns: ['first_name', 'last_name']),      // Composite index
    Index(columns: ['city']),                         // Simple index
  ],
)
```

| Parameter | Type           | Description                     |
| :-------- | :------------- | :------------------------------ |
| `columns` | `List<String>` | Columns included in the index   |
| `unique`  | `bool`         | Enforces uniqueness across rows |

> [!IMPORTANT]
> Always add an index on foreign key columns (`user_id`, etc.). Without them, JOIN operations scan the entire table and degrade performance at scale.

---

## Complete Model Example

```dart
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

part 'user.sql.g.dart';

@Schema(
  tableName: 'users',
  paranoid: true,
  columnNaming: ColumnNamingStrategy.snakeCase,
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['first_name', 'last_name']),
  ],
  relationships: [
    HasMany(model: Order, foreignKey: 'user_id'),
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

  @Column()
  final String phone;

  @Column()
  final String? birthDate;

  @Column()
  final int? age;

  @Column(
    validators: [
      ContainsValidator(['M', 'F', 'Other'], constraint: 'gender_check')
    ],
  )
  final String gender;

  @Column()
  final String city;

  @Column()
  final String country;

  @Column()
  final String? address;

  @Column(defaultValue: true)
  final bool isActive;

  @Column(defaultValue: false)
  final bool isVerified;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.birthDate,
    this.age,
    required this.gender,
    required this.city,
    required this.country,
    this.address,
    this.isActive = true,
    this.isVerified = false,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}
```
