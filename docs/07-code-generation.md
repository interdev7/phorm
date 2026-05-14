# Code Generation (sqflow_generator)

`sqflow_generator` is a `build_runner` plugin that reads your `@Schema` annotated classes and generates:

- SQL `CREATE TABLE` statement with indexes
- `_$SQFlowClassNameMixin` mixin with automatic `toJson()`, `toString()` and `copyWith()`
- `_$SQFlowClassNameFromJson()` helper
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
mixin _$SQFlowUserMixin {
  // toJson — automatic TOP-LEVEL serialization
  Map<String, dynamic> toJson() => _$SQFlowUserToJson(this as User);

  // toString — automatic implementation for debugging
  @override
  String toString() => _$SQFlowUserToString(this as User);

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
User _$SQFlowUserFromJson(Map<String, dynamic> json) => User(
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
  fromJson: _$SQFlowUserFromJson,
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
class User extends Model with _$SQFlowUserMixin {
  @ID()
  final String id;

  @Column()
  final String firstName;

  User({
    required this.id,
    required this.firstName,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
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

When `timestamps: true` (default), the generator automatically adds the following fields to your `_$SQFlowClassNameMixin`:

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
  useToJson: false,   // Don't generate _$SQFlowUserToJson
  useFromJson: false, // Don't generate _$SQFlowUserFromJson
  useCopyWith: false, // Don't generate copyWith
)
class User extends Model with _$SQFlowUserMixin { ... }
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

### `_$SQFlowUserMixin` not found

Make sure:

1. The file has `part 'user.sql.g.dart';`
2. The class has `with _$SQFlowUserMixin` (capital `SQ`, capital `F`, capital `U`)
3. The generator has been run successfully

> [!NOTE]
> The generated mixin name follows the pattern: `_$SQFlow` + `ClassName` + `Mixin`.
> For `class MyModel` → `_$SQFlowMyModelMixin`
> For `class UserProfile` → `_$SQFlowUserProfileMixin`
