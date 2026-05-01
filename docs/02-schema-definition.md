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

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `tableName` | `String?` | class name | Explicit SQL table name |
| `paranoid` | `bool` | `false` | Soft delete support |
| `timestamps` | `bool` | `true` | Auto `created_at`/`updated_at` |
| `columnNaming` | `ColumnNamingStrategy` | `snakeCase` | Field → column mapping strategy |
| `indexes` | `List<Index>` | `[]` | Table indexes |
| `relationships` | `List<Relationship>` | `[]` | `HasMany`, `HasOne`, `BelongsTo` |
| `useToJson` | `bool` | `true` | Generate toJson mixin |
| `useFromJson` | `bool` | `true` | Generate fromJson helper |
| `useCopyWith` | `bool` | `true` | Generate copyWith method |

### Column Naming Strategies

| Strategy | Dart field | SQL column |
| :--- | :--- | :--- |
| `snakeCase` (default) | `firstName` | `first_name` |
| `camelCase` | `firstName` | `firstName` |
| `pascalCase` | `firstName` | `FirstName` |

---

## `@ID`

Marks a field as the primary key. Always `NOT NULL`.

```dart
@ID(type: TEXT(), autoIncrement: false, unique: true)
@override
final String id;

// Integer auto-increment PK
@ID(type: INTEGER(), autoIncrement: true)
@override
final int id;
```

### `@ID` Parameters

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `type` | `DataType` | required | SQLite data type |
| `autoIncrement` | `bool` | `false` | Auto-increment (for `INTEGER` PK) |
| `unique` | `bool` | `true` | Enforce uniqueness |
| `columnName` | `String?` | `null` | Override column name |

> [!WARNING]
> `autoIncrement: true` only works with `INTEGER()` type. For string UUIDs, use `autoIncrement: false` (default).

---

## `@Column`

Defines a regular column.

```dart
@Column(type: TEXT())
final String firstName;

@Column(type: TEXT(), unique: true)
final String email;

@Column(type: INTEGER(), nullable: true)
final int? age;

@Column(type: INTEGER(), defaultValue: true)
final bool isActive;

@Column(
  type: TEXT(),
  check: CHECK(['M', 'F', 'Other'], constraint: 'gender_check'),
)
final String gender;

// Explicit column name (overrides naming strategy)
@Column(type: TEXT(), columnName: 'user_city')
final String city;
```

### `@Column` Parameters

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `type` | `DataType` | required | SQLite data type |
| `columnName` | `String?` | `null` | Override column name |
| `unique` | `bool` | `false` | `UNIQUE` constraint |
| `defaultValue` | `dynamic` | `null` | SQL `DEFAULT` value |
| `check` | `CHECK?` | `null` | Value constraint |

---

## Data Types

All types are classes from `sqflow_platform_interface`. Use them as constructor calls.

| Class | SQLite type | Dart type | Notes |
| :--- | :--- | :--- | :--- |
| `TEXT()` | `TEXT` | `String` | Strings, UUIDs, ISO dates |
| `INTEGER()` | `INTEGER` | `int`, `bool` | Booleans stored as `1`/`0` |
| `REAL()` | `REAL` | `double` | Floating point numbers |
| `BLOB()` | `BLOB` | `Uint8List` | Binary data |
| `NUMERIC()` | `NUMERIC` | `num` | Integer or float |

> [!NOTE]
> There is no dedicated `BOOLEAN` or `DATETIME` class. Use `INTEGER()` for booleans and `TEXT()` for dates (stored as ISO-8601 strings). The generator handles the conversion automatically.

---

## `CHECK` Constraint

Restricts allowed values at the database level.

```dart
// Simple list of allowed values
@Column(
  type: TEXT(),
  check: CHECK(['active', 'inactive', 'pending']),
)
final String status;

// With explicit constraint name (useful for error messages)
@Column(
  type: TEXT(),
  check: CHECK(['M', 'F', 'Other'], constraint: 'gender_check'),
)
final String gender;
```

> [!TIP]
> Use `CHECK` for small, stable domain values (enums). For complex validation, handle it in Dart before saving.

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

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `columns` | `List<String>` | Columns included in the index |
| `unique` | `bool` | Enforces uniqueness across rows |

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
  @ID(type: TEXT(), autoIncrement: false, unique: true)
  @override
  final String id;

  @Column(type: TEXT())
  final String firstName;

  @Column(type: TEXT())
  final String lastName;

  @Column(type: TEXT(), unique: true)
  final String email;

  @Column(type: TEXT())
  final String phone;

  @Column(type: TEXT())
  final String? birthDate;

  @Column(type: INTEGER())
  final int? age;

  @Column(
    type: TEXT(),
    check: CHECK(['M', 'F', 'Other'], constraint: 'gender_check'),
  )
  final String gender;

  @Column(type: TEXT())
  final String city;

  @Column(type: TEXT())
  final String country;

  @Column(type: TEXT())
  final String? address;

  @Column(type: INTEGER(), defaultValue: true)
  final bool isActive;

  @Column(type: INTEGER(), defaultValue: false)
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

  @override
  Map<String, dynamic> toJson() => _$SQFlowUserToJson();

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}
```
