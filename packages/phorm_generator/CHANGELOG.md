# Changelog

## 1.0.3

- Lowered `analyzer` constraint to `>=6.4.1 <6.9.0` for compatibility with Dart 3.7 SDKs (avoids the unavailable `_macros` package).
- Updated element accessors to the matching analyzer API (`enclosingElement`, `getDisplayString(withNullability: true)`).

## 1.0.2

- Updated SDK environment constraint to >=3.7.0 <4.0.0
- Restored analyzer dependency to ^6.11.0 to resolve build errors

## 1.0.1

- Updated README with badges
- Removed commented workspace resolution configuration

## 1.0.0

- First stable release.
- Automatically generates optimized SQL schemas (tables, indices, foreign keys) and DDL from annotations.
- Produces type-safe relational model mixins (`_$PhormModelMixin`) and pluralized service accessors.
- Provides highly optimized `_$PhormModelFromJson` methods for fast JSON mapping.
- Integrates with `build_runner` and `source_gen` for hot-reloadable, automated code generation.
