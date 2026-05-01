# Code Generation (sqflow_generator)

`sqflow_generator` is a `build_runner` plugin that reads your `@Schema` annotated classes and generates:
- SQL `CREATE TABLE` statement with indexes
- `_$SQFlowClassName` mixin with `toJson()` and `copyWith()`
- `_$SQFlowClassNameFromJson()` helper
- Relationship field declarations

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

### Generated Mixin (`_$SQFlowUserMixin`)

```dart
mixin _$SQFlowUserMixin on Model {
  // toJson — serializes to database format
  Map<String, dynamic> _$SQFlowUserToJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };

  // copyWith — immutable update pattern
  User copyWith({
    String? id,
    String? firstName,
    ...
  }) => User(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    ...
  );
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
  type: User,
  primaryKey: 'id',
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

  @Column(type: TEXT(), unique: true)
  final String email;

  @Column(type: INTEGER(), defaultValue: true)
  final bool isActive;

  User({
    required this.id,
    required this.firstName,
    required this.email,
    this.isActive = true,
  });

  @override
  Map<String, dynamic> toJson() => _$SQFlowUserToJson();

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
}
```

```dart
// Service setup (in your repository or service class)
import 'user.sql.g.dart'; // Contains usersTable

final db = DB.autoVersion(
  databaseName: 'app.db',
  tables: [usersTable, ordersTable],
);

final userService = SqflowCore<User>(
  dbManager: db,
  table: usersTable,
);
```

---

## Automatic Timestamp Fields

When `timestamps: true` (default), the generator **does not add** Dart fields for `createdAt`/`updatedAt`/`deletedAt` to your class. Instead, these are injected at the database level by `SqflowCore._withTimestamps()`.

> [!IMPORTANT]
> If you need to access `createdAt` or `updatedAt` in your Dart model (e.g., to display in UI), you **must declare these fields manually** in your class and include them in `fromJson`. The generator adds them to the SQL schema but does not generate Dart fields for them.

```dart
// Manual timestamp fields (if you need them in Dart)
@Column(type: TEXT())
final DateTime? createdAt;

@Column(type: TEXT())
final DateTime? updatedAt;
```

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
