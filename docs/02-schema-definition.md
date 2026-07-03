# Schema Definition

All schema configuration is done via annotations from `phorm_annotations`. The `phorm_generator` reads these annotations and generates the SQL schema, mixins, and serialization helpers.

---

## `@Schema`

Defines table-level configuration for a class.

```dart
@Schema(
  tableName: 'users',         // Optional. Defaults to class name in snakeCase
  paranoid: true,             // Enable soft deletes (requires deleted_at column)
  timestamps: true,           // Auto-inject created_at / updated_at (default: true)
  columnNaming: ColumnNamingStrategy.snakeCase, // default
  dialect: SqlDialectKind.sqlite, // Target DDL dialect (default: sqlite)
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['first_name', 'last_name']),
  ],
  relationships: [
    HasMany(model: Post, foreignKey: 'user_id'),
    HasOne(model: Profile, foreignKey: 'user_id'),
  ],
  useToJson: true,    // Generate _$PhormClassToJson() (default: true)
  useFromJson: true,  // Generate _$PhormClassFromJson() (default: true)
  useCopyWith: true,  // Generate copyWith() (default: true)
  generateFullService: true, // Generate the pluralized service class, e.g. Users (default: true)
)
class User extends Model with _$PhormUserMixin { ... }
```

### `@Schema` Parameters

| Parameter       | Type                   | Default     | Description                                           |
| :-------------- | :--------------------- | :---------- | :---------------------------------------------------- |
| `tableName`     | `String?`              | class name  | Explicit SQL table name                               |
| `paranoid`      | `bool`                 | `false`     | Soft delete support                                   |
| `timestamps`    | `bool`                 | `true`      | Auto `created_at`/`updated_at`                        |
| `columnNaming`  | `ColumnNamingStrategy` | `snakeCase` | Field → column mapping strategy                       |
| `dialect`       | `SqlDialectKind`       | `sqlite`    | Target SQL dialect for DDL generation (`sqlite`, `postgres`, `mysql`) |
| `indexes`       | `List<Index>`          | `[]`        | Table indexes                                         |
| `relationships` | `List<Relationship>`   | `[]`        | `HasMany`, `HasOne`, `BelongsTo`/`Join`, `ManyToMany` (see note below) |
| `useToJson`     | `bool`                 | `true`      | Generate toJson mixin                                 |
| `useFromJson`   | `bool`                 | `true`      | Generate fromJson helper                              |
| `useCopyWith`   | `bool`                 | `true`      | Generate copyWith method                              |
| `useValidator`  | `bool`                 | `true`      | Generate validate() method                            |
| `useToString`   | `bool`                 | `true`      | Generate toString() helper                            |
| `generateFullService` | `bool`           | `true`      | Generate the pluralized static service class (e.g. `Users`) exposing the full CRUD/query API (`insert`, `readAll`, `where`, `watchAll`, column constants, …). Set `false` to keep only the lightweight artefacts (schema, table, `fromJson`/`toJson`, `copyWith`). |

> [!NOTE]
> Relationships are declarations used for querying and eager loading — the
> generator does **not** create the related tables. The one exception is
> `ManyToMany(createPivot: true)`, which appends a
> `CREATE TABLE IF NOT EXISTS <pivot>` to the generated schema so the join table
> is created automatically (optionally with `ON DELETE CASCADE` foreign keys via
> `pivotForeignKeys: true`). See the
> [Many-to-Many](file:///Users/interdev7/Documents/phorm/docs/11-many-to-many.md)
> guide for details.

### Target SQL Dialect

`dialect` tells the generator which database flavour to emit DDL for. It defaults
to `SqlDialectKind.sqlite`, so existing schemas are unaffected. SQLite is fully
implemented; `postgres` and `mysql` are scaffolded (their type mapping is in
place, with remaining DDL specifics tracked as TODOs in `phorm_generator`).

```dart
@Schema(dialect: SqlDialectKind.postgres)
class User extends Model with _$PhormUserMixin { ... }
```

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

// Custom primary key column name (runtime primaryKey: 'user_uid')
@ID(columnName: 'user_uid')
@override
final String uid;
```

### Automatic Primary Key Resolution

The `phorm_generator` automatically identifies the primary key of your model by looking for the `@ID` annotation.

1. **SQL Schema**: It adds the `PRIMARY KEY` constraint to the corresponding column in the generated `CREATE TABLE` statement.
2. **Table Configuration**: It automatically injects the `primaryKey` column name into the generated `Table` instance (e.g., `primaryKey: 'user_uid'`).
3. **Runtime Support**: The `PhormCore` engine uses `table.primaryKey` to perform ID-based lookups (`readOne`, `delete`, etc.), ensuring that custom primary key names work seamlessly.
4. **Relationship Resolution**: Other models referencing this model via `BelongsTo` or `ManyToMany` will automatically use this primary key name for foreign key serialization.

> [!NOTE]
> If no field is annotated with `@ID`, the generator will default to `id`, but it is highly recommended to explicitly annotate your primary key field.

### `@ID` Parameters

| Parameter       | Type      | Default  | Description                     |
| :-------------- | :-------- | :------- | :------------------------------ |
| `sqlType`       | `String?` | inferred | Explicit SQLite type override   |
| `autoIncrement` | `bool`    | `false`  | Auto-increment (for `int` PK)   |
| `unique`        | `bool`    | `true`   | Enforce uniqueness              |
| `columnName`    | `String?` | `null`   | Override column name            |
| `collate`       | `String?` | `null`   | SQLite collation (NOCASE, etc.) |

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

@Column()
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

// Explicit SQL type override (raw string)
@Column(sqlType: 'VARCHAR(255)')
final String bio;

// Typed SQL type override (SqlType object)
@Column(type: VARCHAR(255))
final String title;
```

| Parameter      | Type                | Default  | Description                          |
| :------------- | :------------------ | :------- | :----------------------------------- |
| `sqlType`      | `String?`           | inferred | Explicit SQL type override as a raw string |
| `type`         | `SqlType?`          | inferred | Explicit SQL type as a typed object (e.g. `VARCHAR(255)`, `DECIMAL(10, 2)`, `JSONB()`) |
| `columnName`   | `String?`           | `null`   | Override column name                 |
| `unique`       | `bool`              | `false`  | `UNIQUE` constraint                  |
| `defaultValue` | `dynamic`           | `null`   | SQL `DEFAULT` value                  |
| `validators`   | `List<IValidator>?` | `null`   | Value constraints (Check/Regex/etc.) |
| `converter`    | `ValueConverter?`   | `null`   | Custom type transformer              |
| `collate`      | `String?`           | `null`   | SQLite collation (NOCASE, etc.)      |

---

## Data Types

PHORM automatically infers the SQLite data type from your Dart field types. You generally do not need to specify `sqlType` manually.

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
@Column(sqlType: SqlTypes.text)
final String bio;

// Or with extra SQLite modifiers
@Column(sqlType: '${SqlTypes.text} COLLATE NOCASE')
final String username;
```

> [!TIP]
> You can use the **`SqlTypes`** class for standard type names instead of hardcoding strings.

### Typed Column Definitions (`type:`)

Instead of a raw `sqlType` string, you can pass a typed **`SqlType`** object via
`type:`. This is checked at compile time and reads more clearly for
parameterized types:

```dart
@Column(type: VARCHAR(255))
final String title;

@Column(type: DECIMAL(10, 2))
final double price;

@Column(type: JSONB()) // Postgres
final Map<String, dynamic> metadata;
```

`SqlType` classes are organised by dialect (all exported from
`phorm_annotations`):

| File                       | Types                                                                                       |
| :------------------------- | :------------------------------------------------------------------------------------------ |
| `sql_types/common_types`   | `VARCHAR(length)`, `TEXT`, `INTEGER`, `BIGINT`, `BOOLEAN`, `REAL`, `DOUBLE`, `DECIMAL(p, s)`, `DATE`, `TIME`, `TIMESTAMP`, `BLOB`, `JSON` |
| `sql_types/sqlite_types`   | `NUMERIC`, `Collate`                                                                         |
| `sql_types/postgres_types` | `JSONB`                                                                                      |
| `sql_types/mysql_types`    | _(MySQL-only types — scaffolded)_                                                            |

> [!NOTE]
> Type resolution precedence in the generator: `sqlType` (raw string) →
> `type` (`SqlType` object) → `converter`'s SQL type → inferred from the Dart
> field type. The first one provided wins.

> [!NOTE]
> For booleans and dates, the generator handles conversion between Dart types and SQLite representations automatically.

### String Collations (NOCASE, BINARY)

SQLite allows you to specify how strings are compared using the `COLLATE` clause. This is especially useful for case-insensitive searching or sorting.

- **`BINARY`** (default): Case-sensitive comparison. `'Alice' != 'alice'`.
- **`NOCASE`**: Case-insensitive comparison (for ASCII characters). `'Alice' == 'alice'`.

You can apply these using the `collate` property:

```dart
@Column(collate: Collate.noCase)
final String email;

@Column(collate: Collate.binary) // Explicit binary
final String password;
```

---

## Value Converters

Value Converters allow you to transform complex Dart types into simple types supported by SQLite (and vice versa). This is useful for storing objects like `Map`, `List`, Enums, or custom domain objects as `TEXT`, `INTEGER`, or `BLOB` in the database.

### Why use Value Converters?

- **Support for any data type**: Store complex objects (Colors, Points, custom classes) in standard SQL columns.
- **Encapsulation**: Keep transformation logic (like `jsonEncode`/`jsonDecode`) in one place instead of scattering it throughout your UI or service layers.
- **Type Safety**: Work with strongly-typed objects in your Dart code while the converter handles the low-level SQL representation.
- **Automatic Integration**: PHORM automatically uses converters in `toJson()`, `fromJson()`, and database operations.

### Creating a Converter

To create a converter, inherit from `ValueConverter<DartType, SqlType>` and implement `fromSql` and `toSql`.

```dart
class JsonMapConverter extends ValueConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String sqlValue) {
    return jsonDecode(sqlValue) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}
```

### Example: Storing an Enum

Instead of manually converting Enums to strings everywhere, use a converter:

```dart
enum UserRole { admin, editor, user }

class RoleConverter extends ValueConverter<UserRole, String> {
  const RoleConverter();

  @override
  UserRole fromSql(String sqlValue) =>
      UserRole.values.firstWhere((e) => e.name == sqlValue);

  @override
  String toSql(UserRole value) => value.name;
}

// In your model:
@Column(converter: RoleConverter())
final UserRole role;
```

### Using a Converter

Apply the converter to a field using the `converter` parameter in `@Column`.

```dart
@Column(converter: JsonMapConverter())
final Map<String, dynamic>? metadata;
```

### How it Works

1.  **To Database**: When you save a model or call `toJson()`, PHORM calls `converter.toSql()`.
2.  **From Database**: When you read a model or call `fromJson()`, PHORM calls `converter.fromSql()`.

> [!IMPORTANT]
> The converter must have a **`const`** constructor so it can be used inside the `@Column` annotation.

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

For a full list of available validators and details on how they work, see the [Validators](file:///Users/interdev7/Documents/phorm/docs/10-validators.md) documentation.

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
  relationships: [
    HasMany(model: Order, foreignKey: 'user_id'),
  ],
)
class User extends Model with _$PhormUserMixin {
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

  factory User.fromJson(Map<String, dynamic> json) => _$PhormUserFromJson(json);
}
```
