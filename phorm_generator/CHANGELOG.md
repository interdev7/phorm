# Changelog

## [1.1.0] - 2026-04-28

- Added support for ORM Relationships: `@HasMany`, `@HasOne`, `@BelongsTo`, and `@Join`.
- Enhanced `SqliteSchemaGenerator` to extract relationship metadata from both `@Schema` and class fields.
- Merged redundant generators into a single, optimized `SqliteSchemaGenerator`.
- Improved column naming strategy integration for complex schemas.
- Added automatic registration of relationships in the generated `Table` classes.

## [1.0.0] - 2026-01-28

- First stable release.
- SQL schema generation for Flutter based on annotations.
- Integration with `build_runner` and `source_gen` for automatic code generation.
- Support for the `sqflow_annotations` package.
- Automatic formatting of generated Dart code using `dart_style`.
