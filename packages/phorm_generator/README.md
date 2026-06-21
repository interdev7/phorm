# 🏗️ PHORM Generator

[![Pub Version](https://img.shields.io/pub/v/phorm_generator.svg)](https://pub.dev/packages/phorm_generator)
[![Build Status](https://github.com/interdev7/phorm/actions/workflows/main.yml/badge.svg)](https://github.com/interdev7/phorm/actions)
[![Coverage](https://codecov.io/gh/interdev7/phorm/branch/main/graph/badge.svg?flag=phorm_generator)](https://codecov.io/gh/interdev7/phorm)
[![GitHub Stars](https://img.shields.io/github/stars/interdev7/phorm.svg?style=flat&logo=github)](https://github.com/interdev7/phorm)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.5.0-blue?logo=dart)](https://dart.dev)

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

MIT License
