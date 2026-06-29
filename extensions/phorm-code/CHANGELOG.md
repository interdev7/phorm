# Changelog

## 0.1.0

### Fixed

- Class boundaries are now detected by brace matching, so top-level code
  between or after classes (functions, constants, extensions) is no longer
  swallowed or destroyed during conversion.
- Conversions are applied through an undoable `WorkspaceEdit` and respect
  unsaved buffer changes, instead of writing directly to disk.
- Existing methods, getters and custom `fromJson` factories are preserved; the
  converter only injects annotations, the `id` field, the constructor and a
  `fromJson` when missing.
- Field detection is brace-depth aware: statements inside method bodies,
  getters/setters and static members are no longer mistaken for fields.
- Class headers using `$` (e.g. `with _$PhormXMixin`) and generic classes are
  parsed correctly.

### Added

- Settings: `phorm.generateFullService`, `phorm.timestamps`, `phorm.paranoid`,
  `phorm.addFromJson`, `phorm.enableCodeLens` — emitted as the matching
  `@Schema` options.
- CodeLens "⚡ To PHORM Model" above plain classes, plus conversion of just the
  class under the cursor.
- Command "Phorm: Run build_runner build".
- Snippets: `phormmodel`, `phormschema`, `phormcolumn`, `phormid`.

### Internal

- Unit tests (vitest), ESLint configuration and CI (compile + lint + test).
- Marketplace metadata (keywords, license, homepage, bugs, categories).

## 0.0.1

- Initial release: convert plain Dart classes to PHORM models.
