# PHORM — VS Code Extension

Convert regular Dart classes into PHORM models with a single click.

## Usage

1. Right-click a `.dart` file in the Explorer → **To PHORM Model**
2. Or right-click inside the editor → **To PHORM Model**
3. Or click the **⚡ To PHORM Model** CodeLens shown above any plain class to
   convert just that class.

Conversions are applied as a normal, **undoable** edit (Ctrl/Cmd+Z works) and
respect unsaved changes in the buffer.

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
- Existing methods, getters and a custom `fromJson` are **preserved** (the
  converter only injects annotations, the `id` field, the constructor and a
  `fromJson` factory when one is missing)
- Top-level code outside the class (functions, constants, extensions) is left
  untouched
- Already converted classes (`extends Model`) are skipped

## Settings

| Setting                     | Default | Effect                                                                 |
| :-------------------------- | :------ | :--------------------------------------------------------------------- |
| `phorm.generateFullService` | `true`  | When `false`, emits `@Schema(generateFullService: false)`.             |
| `phorm.timestamps`          | `true`  | When `false`, emits `@Schema(timestamps: false)`.                      |
| `phorm.paranoid`            | `false` | When `true`, emits `@Schema(paranoid: true)` (soft deletes).           |
| `phorm.addFromJson`         | `true`  | Generate a `fromJson` factory (skipped if one already exists).         |
| `phorm.enableCodeLens`      | `true`  | Show the "To PHORM Model" CodeLens above plain classes.                |

## Snippets

`phormmodel`, `phormschema`, `phormcolumn`, `phormid` scaffold common PHORM
declarations.

## After Conversion

Run code generation via the command palette **Phorm: Run build_runner build**,
or:

```bash
dart run build_runner build --delete-conflicting-outputs
```
