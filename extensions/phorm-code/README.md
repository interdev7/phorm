# PHORM — VS Code Extension

Convert regular Dart classes into PHORM models with a single click.

## Usage

1. Right-click a `.dart` file in the Explorer → **To PHORM Model**
2. Or right-click inside the editor → **To PHORM Model**

## What it does

**Before:**

```dart
class User {
  final String name;
  final String email;

  User({required this.name, required this.email});
}
```

**After:**

```dart
import 'package:phorm/phorm.dart';

part 'user.sql.g.dart';

@Schema(tableName: 'users')
class User extends Model with _$PhormUserMixin {
  @ID(autoIncrement: true)
  final int id;

  @Column()
  final String name;

  @Column()
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) =>
      _$PhormUserFromJson(json);
}
```

## Behavior

- Converts all classes in the file automatically
- If an `id` field is missing, adds:

  ```dart
  @ID(autoIncrement: true)
  final int id;
  ```

- If an `id` field already exists and its type is `String`, adds:

  ```dart
  @ID(autoIncrement: false, unique: true)
  ```

- Existing annotations such as `@Column` and `@ID` are preserved
- Already converted classes (`extends Model`) are skipped

## After Conversion

Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```
