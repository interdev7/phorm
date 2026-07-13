/// Standard SQLite referential actions for foreign keys.
/// Used in `Relationship` for `onDelete` and `onUpdate`.
class ReferentialAction {
  /// CASCADE: When the referenced row is deleted/updated,
  /// delete/update the rows that reference it.
  static const String cascade = 'CASCADE';

  /// SET NULL: When the referenced row is deleted/updated,
  /// set the foreign key columns in the referencing rows to NULL.
  static const String setNull = 'SET NULL';

  /// SET DEFAULT: When the referenced row is deleted/updated,
  /// set the foreign key columns in the referencing rows to their default values.
  static const String setDefault = 'SET DEFAULT';

  /// RESTRICT: Prevents the deletion/update of a referenced row
  /// if there are any rows referencing it.
  static const String restrict = 'RESTRICT';

  /// NO ACTION: Similar to RESTRICT, but the check is performed
  /// after other triggers have fired.
  static const String noAction = 'NO ACTION';

  /// Private constructor to prevent instantiation.
  // coverage:ignore-start
  ReferentialAction._();
  // coverage:ignore-end
}
