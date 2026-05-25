# 🏗️ SQFlow Generator

The magic behind SQFlow. This package uses `build_runner` to turn your Dart models into optimized SQL schemas and type-safe CRUD mixins.

---

## What it does

- **SQL Generation**: Creates `CREATE TABLE`, `INDEX`, and `FOREIGN KEY` statements automatically.
- **Model Mixins**: Generates `_$UserMixin` with automatic `toJson`, `toString`, `copyWith`, and relationship getters.
- **Pluralized Services**: Generates the `Users` service class for fluent, static-method-based interaction.
- **JSON Helpers**: Provides optimized `_$UserFromJson` implementations.
- **Runtime Metadata**: Produces the `Table` configuration needed for `SqflowCore`.

---

## Installation

Add these to your `dev_dependencies`:

```yaml
dev_dependencies:
  sqflow_generator: ^latest
  build_runner: ^latest
```

---

## Usage

### 1. Annotate your class
```dart
@Schema(tableName: 'users')
class User extends Model with _$SQFlowUserMixin {
  @ID()
  final String id;

  @Column()
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => _$SQFlowUserFromJson(json);
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

- For annotation details, see [sqflow_platform_interface](../sqflow_platform_interface/README.md).
- For runtime query engine details, see [sqflow_core](../sqflow_core/README.md).
- For the connection manager and SQLite driver implementation, see [sqflow_lite](../sqflow_lite/README.md).

---

## License

Apache 2.0

