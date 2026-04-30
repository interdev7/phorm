<div style="padding-top: 50px;" align="center">
  <image src="https://github.com/interdev7/sqflow/blob/main/assets/logo/sqflow_logo_screen.png"  alt="SqFlow" height="300" />
</div>

# SQFlow

A lightweight, type-safe SQLite abstraction for Dart and Flutter.

`sqflow` provides a clean repository-style API with:

- safe query builders (no raw SQL concatenation),
- built-in pagination and filtering,
- soft deletes and timestamps,
- batch & transaction support,
- predictable and testable data access.

## Packages

This workspace contains the following packages:

- [`sqflow_core`](./sqflow_core): Core logic, CRUD operations, query builders (`WhereBuilder`, `SortBuilder`), and smart migration tracking.
- [`sqflow_platform_interface`](./sqflow_platform_interface): Annotation library for declarative SQL table and schema definitions in Dart.
- [`sqflow_generator`](./sqflow_generator): SQL Table Schema Generator for Flutter.

## Features

### Performance & Relationships
SQFlow uses a **Single-Query JOIN** architecture to load relationships (`HasMany`, `BelongsTo`, `HasOne`) in one go using SQLite's JSON aggregation functions. This prevents the common N+1 query problem.

> [!TIP]
> To maximize performance on large datasets, always define indices on foreign key columns in your `@Schema`.

### Column Filtering (Attributes)
You can select only specific columns (attributes) to reduce memory usage and query time, similar to Sequelize:

```dart
// Fetch only specific columns
final users = await userService.readAll(
  attributes: Attribute.include(['id', 'first_name', 'email'])
);

// Exclude sensitive or heavy columns
final profiles = await userService.readAll(
  attributes: Attribute.exclude(['internal_notes', 'raw_metadata'])
);

// Filter attributes in relationships
final data = await userService.readAll(
  include: [
    Includable.model<Post>(
      attributes: Attribute.include(['title', 'view_count'])
    )
  ]
);
```
