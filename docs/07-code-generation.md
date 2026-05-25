# Code Generation (sqflow_generator)

`sqflow_generator` is a `build_runner` plugin that reads your `@Schema` annotated classes and generates:

- SQL `CREATE TABLE` statement with indexes
- `_$PhormClassNameMixin` mixin with automatic `toJson()`, `toString()` and `copyWith()`
- `_$PhormClassNameFromJson()` helper
- `ClassName` service class (e.g. `Users`) with static CRUD methods and type-safe columns

---

## Setup

```yaml
# pubspec.yaml
dev_dependencies:
  sqflow_generator: ^latest
  build_runner: ^latest
```

---

## Commands

```bash
# One-time build
dart run build_runner build

# Build and automatically resolve conflicts (recommended during development)
dart run build_runner build --delete-conflicting-outputs

# Watch mode — rebuilds on file changes
dart run build_runner watch --delete-conflicting-outputs
```

---

## Anatomy of a Generated File

For a file `lib/models/user.dart` with `part 'user.sql.g.dart';`, the generator produces `lib/models/user.sql.g.dart` containing:

```dart
mixin _$PhormUserMixin {
  // toJson — automatic TOP-LEVEL serialization
  Map<String, dynamic> toJson() => _$PhormUserToJson(this as User);

  // toString — automatic implementation for debugging
  @override
  String toString() => _$PhormUserToString(this as User);

  // copyWith — immutable update pattern
  User copyWith({
    String? id,
    String? firstName,
    ...
  }) => User(
    id: id ?? (this as User).id,
    firstName: firstName ?? (this as User).firstName,
    ...
  );

  // Timestamps are automatically mixed in if enabled
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
}
```

### Generated Service Class (`Users`)

This class is the primary API for your model.

```dart
class Users {
  // Type-safe columns for queries
  static const id = SqflowColumn<String>('id');
  static const firstName = SqflowColumn<String>('first_name');
  ...

  // Static CRUD methods
  static Future<int> insert(User item) => ...;
  static Future<User?> read(Object id) => ...;
  static SqflowQuery<User> where(SqflowCondition c) => ...;
  ...
}
```

### Generated `fromJson` Helper

```dart
User _$PhormUserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  firstName: json['first_name'] as String,
  isActive: (json['is_active'] as int?) == 1,
  createdAt: json['created_at'] != null
      ? DateTime.parse(json['created_at'] as String)
      : null,
  ...
);
```

### Generated Table Configuration

```dart
final usersTable = Table<User>(
  name: 'users',
  schema: '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      ...
      created_at TEXT NOT NULL,
      updated_at TEXT,
      deleted_at TEXT
    );
    CREATE UNIQUE INDEX idx_users_email ON users(email);
    CREATE INDEX idx_users_name ON users(first_name, last_name);
  ''',
  fromJson: _$PhormUserFromJson,
  primaryKey: 'id', // Resolved from @ID annotation (e.g. 'custom_id')
  paranoid: true,
  timestamps: true,
  relationships: [
    HasMany(model: Order, foreignKey: 'user_id'),
  ],
  columns: ['id', 'first_name', 'last_name', 'email', ...],
);
```

---

## How to Use the Generated Code

```dart
// Your model file
part 'user.sql.g.dart';

@Schema(
  tableName: 'users',
  paranoid: true,
)
class User extends Model with _$PhormUserMixin {
  @ID()
  final String id;

  @Column()
  final String firstName;

  User({
    required this.id,
    required this.firstName,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$PhormUserFromJson(json);
}
```

```dart
// Service usage (No manual setup needed!)
import 'user.sql.g.dart';

// 1. Querying
final users = await Users.where(Users.firstName.eq('John')).get();

// 2. CRUD
await Users.insert(newUser);
final user = await Users.readOne('id123');
```

---

## Automatic Timestamp Fields

When `timestamps: true` (default), the generator automatically adds the following fields to your `_$PhormClassNameMixin`:

- `DateTime? createdAt`
- `DateTime? updatedAt`

If `paranoid: true` is enabled, it also adds:

- `DateTime? deletedAt`

These fields are automatically handled in `toJson()` and `fromJson()`, so you can access them directly on your model instances without any manual declaration.

```dart
final user = await Users.readOne('id123');
print(user?.createdAt); // Works automatically!
```

> [!NOTE]
> If you want to customize these fields (e.g., add extra annotations or use a different name), you can still declare them manually in your model class. The generator will detect your manual declaration and won't generate a duplicate field in the mixin.

---

## Generator Control Flags

You can disable specific generated code parts:

```dart
@Schema(
  tableName: 'users',
  useToJson: false,   // Don't generate _$PhormUserToJson
  useFromJson: false, // Don't generate _$PhormUserFromJson
  useCopyWith: false, // Don't generate copyWith
)
class User extends Model with _$PhormUserMixin { ... }
```

This is useful when you have custom serialization logic that conflicts with generated code.

---

## Common Issues

### `part 'file.sql.g.dart'` not found

Run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Generated file is outdated

The generator does not automatically detect changes in non-annotated files (like referenced model classes). Rebuild explicitly when you change relationship target models.

### Conflicting outputs error

```bash
dart run build_runner build --delete-conflicting-outputs
```

### `_$PhormUserMixin` not found

Make sure:

1. The file has `part 'user.sql.g.dart';`
2. The class has `with _$PhormUserMixin` (capital `SQ`, capital `F`, capital `U`)
3. The generator has been run successfully

> [!NOTE]
> The generated mixin name follows the pattern: `_$Phorm` + `ClassName` + `Mixin`.
> For `class MyModel` → `_$PhormMyModelMixin`
> For `class UserProfile` → `_$PhormUserProfileMixin`

---

## Custom SQL Functions Code Generation (`@SqlFunc`)

`sqflow_generator` also provides an automatic code generator for your custom SQLite functions, eliminating all boilerplate (such as manual registry creation, column extensions, and argument casting).

### 1. Annotate Top-Level Dart Functions

Write regular Dart functions containing your custom SQLite function logic and annotate them with `@SqlFunc`:

```dart
// lib/models/custom_functions.dart
import 'package:sqflow/sqflow.dart';

part 'custom_functions.fn.g.dart';

@SqlFunc(name: 'TO_SLUG')
String? toSlug(String? val) {
  if (val == null) return null;
  return val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

@SqlFunc(name: 'DOUBLE')
int? doubleValue(int? val) {
  if (val == null) return null;
  return val * 2;
}
```

### 2. Generate

Run `build_runner`. The generator creates a standalone `.fn.g.dart` file (e.g. `custom_functions.fn.g.dart`):

> [!NOTE]
> The unique `.fn.g.dart` extension prevents output conflicts with other builders like `source_gen:combining_builder`.

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'custom_functions.dart';

// Custom SQL function registrations
final customSqlFunctions = [
  SqlFunction.custom(
    name: 'TO_SLUG',
    argumentCount: 1,
    function: (args) {
      return toSlug(args[0] as String?);
    },
  ),
  SqlFunction.custom(
    name: 'DOUBLE',
    argumentCount: 1,
    function: (args) {
      return doubleValue(args[0] as int?);
    },
  ),
];

// Type-safe column extensions for custom SQL functions
extension toSlugSqflowColumnExtension on SqflowColumn<String> {
  /// Applies the custom SQL function `TO_SLUG` to this column.
  SqflowColumn<String> toSlug() {
    return sqlFunction<String>('TO_SLUG');
  }
}

extension doubleValueSqflowColumnExtension on SqflowColumn<int> {
  /// Applies the custom SQL function `DOUBLE` to this column.
  SqflowColumn<int> doubleValue() {
    return sqlFunction<int>('DOUBLE');
  }
}
```

### 3. Register Custom Functions in Database

Provide `customSqlFunctions` when opening your database:

```dart
final db = await DB.open(
  path: 'path_to_db.db',
  customFunctions: customSqlFunctions,
);
```

### 4. Query Type-Safely

The generated extension methods allow calling your custom SQL functions directly on matching `SqflowColumn` instances:

```dart
// Type-safe query!
final users = await Users.where(
  Users.firstName.toSlug().eq('jane-smith'),
).get();

final doubledUsers = await Users.where(
  Users.age.doubleValue().gt(50),
).get();
```

If you try to call `.doubleValue()` on a `SqflowColumn<String>`, Dart will produce a compile-time error!

---

## Advanced Features & Code Generation Details

The `sqflow_generator` produces highly optimized, clean, and warning-free Dart code by employing smart static analysis.

### 1. Smart Validation Code Generation

To keep the generated files lightweight, **validation methods (`_$validate[ClassName]`) are generated dynamically**:

- If a model class has **no validators** defined on any of its fields, the generator completely omits the helper `_$validate[ClassName]` function and its execution call inside `toJson()`.
- This ensures that generated files stay clean and strictly relevant, avoiding any unused validation boilerplate.

### 2. Elimination of Unused Helper Utilities

The generator performs a static scan of the class attributes and relationships to keep the output pristine:

- The JSON decoder helper `_$PhormDecodeJson` is omitted if it isn't referenced by any custom deserialization rules.
- Unnecessary `_$PhormToJsonValue` helper declarations are excluded when no complex type conversions or collection fields are present in the schema.

### 3. Explicit Type Arguments for Generic Models

For generic model classes (e.g. `class ApiResponse<T>`), the generated Pluralized Service (e.g., `class ApiResponses`) uses explicit type arguments:

```dart
class ApiResponses extends SqflowCore<ApiResponse<dynamic>> { ... }
```

This ensures complete type safety and avoids compiler warnings (_The generic type 'ApiResponse<dynamic>' should have explicit type arguments but doesn't_).

### 4. Overriding Column Names vs Global Strategies

When a `@Schema` defines a global column naming strategy (e.g., `columnNaming: ColumnNamingStrategy.snakeCase`), specific fields can still be overridden using a per-field level configuration:

```dart
@Column(columnName: 'userId')
final String userId;
```

Direct `columnName` overrides have the **highest priority** and are strictly preserved exactly as defined. This allows seamless mapping of backend payload keys to local properties while maintaining global naming strategy conventions.

> [!TIP]
> **Best Practice for API Integration:** If your application communicates with backend APIs or other external services, it is highly recommended to establish unified property naming conventions across your frontend models, database schemas, and backend payloads. Aligning these names beforehand minimizes manual mapping boilerplate, simplifies code maintenance, and prevents any property-naming confusion.
