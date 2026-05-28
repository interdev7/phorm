# 🏗️ PHORM Generator

The magic behind PHORM. This package uses `build_runner` to turn your Dart models into optimized SQL schemas and type-safe CRUD mixins.

---

## What it does

- **SQL Generation**: Creates `CREATE TABLE`, `INDEX`, and `FOREIGN KEY` statements automatically.
- **Model Mixins**: Generates `_$UserMixin` with automatic `toJson`, `toString`, `copyWith`, and relationship getters.
- **Pluralized Services**: Generates the `Users` service class for fluent, static-method-based interaction.
- **JSON Helpers**: Provides optimized `_$UserFromJson` implementations.
- **Runtime Metadata**: Produces the `Table` configuration needed for `PHORM`.

---

## Installation

Add these to your `dev_dependencies`:

```yaml
dev_dependencies:
  phorm_generator: ^latest
  build_runner: ^latest
```

---

## Usage

### 1. Annotate your class

```dart
@Schema(tableName: 'users')
class User extends Model with _$PhormUserMixin {
  @ID()
  final String id;

  @Column()
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$PhormUserFromJson(json);
}
```

### 2. Run the build

```bash
# One-time build
dart run build_runner build

# Watch for changes
dart run build_runner watch --delete-conflicting-outputs
```

---

## Learn More

- For annotation details, see [phorm_annotations](../phorm_annotations/README.md).
- For runtime query engine details, see [phorm](../phorm/README.md).
- For the connection manager and SQLite driver implementation, see [phorm_sqlite](../phorm_sqlite/README.md).

---

## License

Apache 2.0
