// =======================================================
// SORT BUILDER 📊
// =======================================================
import 'package:phorm/phorm.dart' show PhormCore;

/// One ORDER BY entry: a column and its direction.
typedef SortEntry = ({String column, bool descending});

///
/// Fluent builder for SQL ORDER BY clauses. Supports ASC/DESC ordering by columns.
/// Validates column names. Use in [PhormCore.readAll] for sorted results.
///
/// **Key Features:**
/// - Chainable: Multiple columns (e.g., name ASC, age DESC).
/// - Joins with comma (e.g., 'name ASC, age DESC').
/// - Column validation to prevent errors.
class SortBuilder {
  final List<SortEntry> _orders = [];
  static final RegExp _columnRegExp = RegExp(
    r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$',
  );

  void _validate(String column) {
    if (!_columnRegExp.hasMatch(column)) {
      throw ArgumentError(
        'Invalid column name: $column. '
        'Column name must contain only letters, numbers and underscores, and start with a letter or underscore.',
      );
    }
  }

  /// Adds ascending order: `column ASC`.
  ///
  /// **Example:**
  /// ```dart
  /// SortBuilder().asc('name')
  /// ```
  SortBuilder asc(String column) {
    _validate(column);
    _orders.add((column: column, descending: false));
    return this;
  }

  /// Adds descending order: `column DESC`.
  ///
  /// **Example:**
  /// ```dart
  /// SortBuilder().desc('created_at') // Newest first
  /// ```
  SortBuilder desc(String column) {
    _validate(column);
    _orders.add((column: column, descending: true));
    return this;
  }

  /// Builds the full ORDER BY string (or null if empty).
  /// Use with `db.query(orderBy: build())`.
  String? build() =>
      _orders.isEmpty
          ? null
          : _orders
              .map((e) => '${e.column} ${e.descending ? 'DESC' : 'ASC'}')
              .join(', ');

  /// Read-only view of the configured sort entries, in order.
  List<SortEntry> get entries => List.unmodifiable(_orders);

  /// Creates a copy of this SortBuilder
  SortBuilder copy() {
    final copy = SortBuilder();
    copy._orders.addAll(_orders);
    return copy;
  }
}
