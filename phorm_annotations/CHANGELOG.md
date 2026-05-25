# Changelog

All notable changes for the phorm_platform_interface package.

## 1.4.0 — 2026-05-14

- **`Factory<T>`**: Added abstract `Factory<T extends Model>` interface with `create()` and `createMany(int count)` methods.
- **`Seeder`**: Added abstract `Seeder` class with `run(DB db)` method signature (in `seeder.dart` under `phorm_core`).
- **Validators**: Added `json_validators.dart` with `NotEmptyValidator`, `EmailValidator`, `RangeValidator`, `MinLengthValidator`, `MaxLengthValidator`.

## 1.3.0 — 2026-05-08

- **`ManyToMany`**: Added `ManyToMany` relationship annotation with `pivotTable`, `foreignKey`, `relatedKey`, and `relatedLocalKey` parameters.
- **`ReferentialAction`**: Added type-safe `ReferentialAction` enum (`cascade`, `setNull`, `setDefault`, `restrict`, `noAction`) for relationship actions.

## 1.2.0 — 2026-05-01

- **`ValueConverter<D, S>`**: Added `ValueConverter` abstract class for custom type transformations between Dart types and SQLite types.
- **`Collate`**: Added `Collate` constants (`noCase`, `binary`) for SQLite collation support.
- **`result_data.dart`**: Added `Result<T>` and `ResultWithCount<T>` typed result wrappers.
- **`PhormLogger`**: Added `PhormLogger` interface with `PhormConsoleLogger` default implementation.

## 1.1.0 — 2026-04-28

- **Relationship annotations**: Added `HasMany`, `HasOne`, `BelongsTo`, `Join`, and relationship base class.
- **`Includable`**: Added `Includable` class for eager loading API (`Includable.model<T>()`, `Includable.table(name)`).
- **`Attributes`**: Added `Attributes.include([...])` and `Attributes.exclude([...])` for column selection.
- **`@Schema` parameters**: Added `useValidator`, `useToString`, `useCopyWith` options.

## 1.0.0 — 2026-01-23

- First public release.
- `@Schema`, `@Column`, `@ID` annotations for table definition.
- `Model` base class with `toJson()` abstract method.
- `Table<T>` runtime configuration class.
- `TableMigration`, `MigrationBuilder` for schema migrations.
- `PhormDatabaseExecutor` interface.
- `CheckValidator`, `ContainsValidator`, `RegexValidator` for SQL CHECK constraints.
- `SqlTypes` constants for SQLite type names.
- `IndexProps` for table index definitions.
