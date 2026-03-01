<div style="padding-top: 50px;" align="center">
  <image src="https://github.com/interdev7/sqflow/blob/main/assets/logos/sqflow_logo_screen.png"  alt="SqFlow" height="300" />
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
