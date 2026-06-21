# Changelog

## [1.0.1]

- Changed license to MIT
- Updated README with badges
- Removed commented workspace resolution configuration

## 1.0.0

- First stable release.
- Table schema annotations: `@Schema`, `@Column`, `@ID`.
- Database relationship annotations: `@HasMany`, `@HasOne`, `@BelongsTo`, `@ManyToMany`, and `@Join`.
- Support for customizable naming strategies, indexes, and custom JSON serialization options.
- Declarative CHECK validators (e.g. `NotEmptyValidator`, `EmailValidator`).
- Support for database-independent logical types mapping.
- Added `ValueConverter<D, S>` for custom Dart-to-SQL type mappings.
- Added test and seed utilities (`Factory<T>` and `Seeder` interfaces).
