import 'dart:developer';

import 'package:phorm/phorm.dart';

part 'where_condition.dart';

// =======================================================
// WHERE BUILDER 🔍
// =======================================================

///
/// Fluent SQL WHERE clause builder with support for parameterized queries,
/// complex nested conditions, and safe column validation.
///
/// **Key Features:**
/// - Parameterized queries (? placeholders) for SQL injection protection
/// - Column name validation (alphanumeric + underscores)
/// - Nested AND/OR groups with automatic parentheses
/// - Maintains argument order exactly as conditions are added
/// - Complex condition building with raw() method escape hatch
/// - DateTime to ISO string conversion
/// - Tracks used columns for hasConditionOn() checks
///
/// **Basic Usage:**
/// ```dart
/// final where = WhereBuilder()
///   .eq('status', 'active')
///   .gt('age', 18)
///   .like('name', '%John%');
///
/// // Produces: status = ? AND age > ? AND name LIKE ?
/// // Args: ['active', 18, '%John%']
/// ```
class WhereBuilder {
  /// Stores all conditions with their arguments in the order they were added
  final List<_Condition> _conditions = [];

  /// Logical operator to join conditions (default: 'AND')
  final String _separator;

  /// Tracks which columns have been used in conditions
  final Set<String> _usedColumns = {};

  /// Column name validation regex (letters, numbers, underscores, and dots for joined tables)
  static final RegExp _columnRegExp = RegExp(
    r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$',
  );

  /// Creates a new WhereBuilder instance
  ///
  /// **Parameters:**
  /// - `separator`: Logical operator to join conditions (default: 'AND')
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilder(); // Uses AND by default
  /// final orWhere = WhereBuilder(separator: ' OR ');
  /// ```
  WhereBuilder({String separator = 'AND'}) : _separator = separator;

  // =======================================================
  // VALIDATION & UTILITY METHODS
  // =======================================================

  /// Validates column name format
  ///
  /// **Throws:** ArgumentError if column name is invalid
  void _validate(Object column) {
    if (column is SqlFunctionColumn) {
      _validate(column.innerColumn);
      return;
    }
    final colStr = column.toString();
    if (!_columnRegExp.hasMatch(colStr)) {
      throw ArgumentError(
        'Invalid column name: "$colStr". '
        'Must contain only letters, numbers, underscores, '
        'and dots, and parts must start with a letter or underscore.',
      );
    }
  }

  /// Prepares value for SQL insertion
  ///
  /// **Converts:**
  /// - bool → 1/0
  /// - DateTime → ISO 8601 string
  Object? _prepareValue(Object? value) {
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.toIso8601String();
    return value;
  }

  /// Extracts column names from raw SQL for tracking
  void _extractColumnsFromRaw(String condition) {
    final columnRegex = RegExp(
      r'\b([a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)*)\s*(?:=|!=|>|<|>=|<=|LIKE|NOT\s+LIKE|IS|IS\s+NOT|IN|NOT\s+IN|BETWEEN|REGEXP)\b',
      caseSensitive: false,
    );

    final matches = columnRegex.allMatches(condition);
    for (final match in matches) {
      final column = match.group(1)!;
      if (_columnRegExp.hasMatch(column)) {
        _usedColumns.add(column);
      }
    }
  }

  /// Adds a column-based condition; [template] references the column
  /// via [_colToken] so it can be escaped structurally at compile time.
  void _addColumnCondition(Object column, String template, List<Object?> args) {
    _conditions.add(_ColumnCondition(column, template, args));
    _usedColumns.add(column.toString());
  }

  /// Adds a raw SQL condition (no column escaping).
  void _addRawCondition(String sql, List<Object?> args) {
    _conditions.add(_RawCondition(sql, args));
  }

  /// Adds a nested WhereBuilder as a condition
  void _addBuilder(WhereBuilder builder) {
    _conditions.add(_GroupCondition(builder));
    _usedColumns.addAll(builder._usedColumns);
  }

  // =======================================================
  // BASIC COMPARISON OPERATORS (=, !=, >, <, >=, <=)
  // =======================================================

  /// Adds equality condition: `column = ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.eq('status', 'active');
  /// // Produces: status = ?
  /// // Args: ['active']
  /// ```
  WhereBuilder eq(Object column, Object? value) {
    _validate(column);
    if (value == null) return this;
    _addColumnCondition(column, '$_colToken = ?', [_prepareValue(value)]);
    return this;
  }

  /// Adds inequality condition: `column != ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.ne('status', 'inactive');
  /// // Produces: status != ?
  /// // Args: ['inactive']
  /// ```
  WhereBuilder ne(Object column, Object? value) {
    _validate(column);
    if (value == null) return this;
    _addColumnCondition(column, '$_colToken != ?', [_prepareValue(value)]);
    return this;
  }

  /// Adds greater-than condition: `column > ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.gt('age', 18);
  /// // Produces: age > ?
  /// // Args: [18]
  /// ```
  WhereBuilder gt(Object column, Object value) {
    _validate(column);
    _addColumnCondition(column, '$_colToken > ?', [_prepareValue(value)]);
    return this;
  }

  /// Adds greater-than-or-equal condition: `column >= ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.gte('score', 60);
  /// // Produces: score >= ?
  /// // Args: [60]
  /// ```
  WhereBuilder gte(Object column, Object value) {
    _validate(column);
    _addColumnCondition(column, '$_colToken >= ?', [_prepareValue(value)]);
    return this;
  }

  /// Adds less-than condition: `column < ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.lt('age', 65);
  /// // Produces: age < ?
  /// // Args: [65]
  /// ```
  WhereBuilder lt(Object column, Object value) {
    _validate(column);
    _addColumnCondition(column, '$_colToken < ?', [_prepareValue(value)]);
    return this;
  }

  /// Adds less-than-or-equal condition: `column <= ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.lte('quantity', 100);
  /// // Produces: quantity <= ?
  /// // Args: [100]
  /// ```
  WhereBuilder lte(Object column, Object value) {
    _validate(column);
    _addColumnCondition(column, '$_colToken <= ?', [_prepareValue(value)]);
    return this;
  }

  // =======================================================
  // PATTERN MATCHING (LIKE, NOT LIKE, ILIKE)
  // =======================================================

  /// Adds case-sensitive LIKE condition: `column LIKE ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.like('name', '%John%');
  /// // Produces: name LIKE ?
  /// // Args: ['%John%']
  /// ```
  WhereBuilder like(Object column, String pattern) {
    _validate(column);
    _addColumnCondition(column, '$_colToken LIKE ?', [pattern]);
    return this;
  }

  /// Adds NOT LIKE condition: `column NOT LIKE ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.notLike('email', '%spam.com');
  /// // Produces: email NOT LIKE ?
  /// // Args: ['%spam.com']
  /// ```
  WhereBuilder notLike(Object column, String pattern) {
    _validate(column);
    _addColumnCondition(column, '$_colToken NOT LIKE ?', [pattern]);
    return this;
  }

  /// Adds case-insensitive LIKE condition: `LOWER(column) LIKE LOWER(?)`
  ///
  /// **Example:**
  /// ```dart
  /// where.ilike('name', '%john%');
  /// // Produces: LOWER(name) LIKE LOWER(?)
  /// // Args: ['%john%']
  /// ```
  WhereBuilder ilike(Object column, String pattern) {
    _validate(column);
    _addColumnCondition(column, 'LOWER($_colToken) LIKE LOWER(?)', [pattern]);
    return this;
  }

  /// Adds case-insensitive NOT LIKE condition: `LOWER(column) NOT LIKE LOWER(?)`
  ///
  /// **Example:**
  /// ```dart
  /// where.notIlike('name', '%test%');
  /// // Produces: LOWER(name) NOT LIKE LOWER(?)
  /// // Args: ['%test%']
  /// ```
  WhereBuilder notIlike(Object column, String pattern) {
    _validate(column);
    _addColumnCondition(column, 'LOWER($_colToken) NOT LIKE LOWER(?)', [
      pattern,
    ]);
    return this;
  }

  /// Adds REGEXP condition: `column REGEXP ?` (SQLite)
  ///
  /// **Example:**
  /// ```dart
  /// where.regexp('phone', '^[0-9]{10}\$');
  /// // Produces: phone REGEXP ?
  /// // Args: ['^[0-9]{10}\$']
  /// ```
  WhereBuilder regexp(Object column, String pattern) {
    _validate(column);
    _addColumnCondition(column, '$_colToken REGEXP ?', [pattern]);
    return this;
  }

  // =======================================================
  // STRING FUNCTIONS (LENGTH, SUBSTR)
  // =======================================================

  /// Adds condition on the length of a column: `LENGTH(column) = ?`
  WhereBuilder lengthEq(Object column, int length) {
    _validate(column);
    _addColumnCondition(column, 'LENGTH($_colToken) = ?', [
      _prepareValue(length),
    ]);
    return this;
  }

  /// Adds condition on the length of a column: `LENGTH(column) != ?`
  WhereBuilder lengthNe(Object column, int length) {
    _validate(column);
    _addColumnCondition(column, 'LENGTH($_colToken) != ?', [
      _prepareValue(length),
    ]);
    return this;
  }

  /// Adds greater-than condition on the length: `LENGTH(column) > ?`
  WhereBuilder lengthGt(Object column, int length) {
    _validate(column);
    _addColumnCondition(column, 'LENGTH($_colToken) > ?', [
      _prepareValue(length),
    ]);
    return this;
  }

  /// Adds greater-than-or-equal condition on the length: `LENGTH(column) >= ?`
  WhereBuilder lengthGte(Object column, int length) {
    _validate(column);
    _addColumnCondition(column, 'LENGTH($_colToken) >= ?', [
      _prepareValue(length),
    ]);
    return this;
  }

  /// Adds less-than condition on the length: `LENGTH(column) < ?`
  WhereBuilder lengthLt(Object column, int length) {
    _validate(column);
    _addColumnCondition(column, 'LENGTH($_colToken) < ?', [
      _prepareValue(length),
    ]);
    return this;
  }

  /// Adds less-than-or-equal condition on the length: `LENGTH(column) <= ?`
  WhereBuilder lengthLte(Object column, int length) {
    _validate(column);
    _addColumnCondition(column, 'LENGTH($_colToken) <= ?', [
      _prepareValue(length),
    ]);
    return this;
  }

  /// Adds SUBSTR equality: `SUBSTR(column, start, len) = ?`
  ///
  /// `start` and `len` are passed as parameters to preserve ordering
  /// and avoid embedding literals directly into SQL.
  WhereBuilder substrEq(Object column, int start, int len, String value) {
    _validate(column);
    _addColumnCondition(column, 'SUBSTR($_colToken, ?, ?) = ?', [
      _prepareValue(start),
      _prepareValue(len),
      _prepareValue(value),
    ]);
    return this;
  }

  /// Adds SUBSTR LIKE condition: `SUBSTR(column, start, len) LIKE ?`
  WhereBuilder substrLike(Object column, int start, int len, String pattern) {
    _validate(column);
    _addColumnCondition(column, 'SUBSTR($_colToken, ?, ?) LIKE ?', [
      _prepareValue(start),
      _prepareValue(len),
      pattern,
    ]);
    return this;
  }

  /// Adds case-insensitive SUBSTR LIKE: `LOWER(SUBSTR(column, start, len)) LIKE LOWER(?)`
  WhereBuilder substrIlike(Object column, int start, int len, String pattern) {
    _validate(column);
    _addColumnCondition(
      column,
      'LOWER(SUBSTR($_colToken, ?, ?)) LIKE LOWER(?)',
      [_prepareValue(start), _prepareValue(len), pattern],
    );
    return this;
  }

  // =======================================================
  // RANGE & SET OPERATIONS (BETWEEN, IN, NOT IN)
  // =======================================================

  /// Adds range condition: `column BETWEEN ? AND ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.between('age', 18, 65);
  /// // Produces: age BETWEEN ? AND ?
  /// // Args: [18, 65]
  /// ```
  WhereBuilder between(Object column, Object from, Object to) {
    _validate(column);
    _addColumnCondition(column, '$_colToken BETWEEN ? AND ?', [
      _prepareValue(from),
      _prepareValue(to),
    ]);
    return this;
  }

  /// Adds NOT BETWEEN condition: `column NOT BETWEEN ? AND ?`
  WhereBuilder notBetween(Object column, Object from, Object to) {
    _validate(column);
    _addColumnCondition(column, '$_colToken NOT BETWEEN ? AND ?', [
      _prepareValue(from),
      _prepareValue(to),
    ]);
    return this;
  }

  /// Adds STARTS WITH condition (LIKE 'pattern%')
  WhereBuilder startsWith(Object column, String pattern) {
    _validate(column);
    _addColumnCondition(column, '$_colToken LIKE ?', ['$pattern%']);
    return this;
  }

  /// Adds ENDS WITH condition (LIKE '%pattern')
  WhereBuilder endsWith(Object column, String pattern) {
    _validate(column);
    _addColumnCondition(column, '$_colToken LIKE ?', ['%$pattern']);
    return this;
  }

  /// Adds IN condition: `column IN (?, ?, ...)`
  ///
  /// **Example:**
  /// ```dart
  /// where.inList('status', ['active', 'pending']);
  /// // Produces: status IN (?, ?)
  /// // Args: ['active', 'pending']
  /// ```
  WhereBuilder inList(Object column, List<Object?> values) {
    _validate(column);
    if (values.isEmpty) {
      _addColumnCondition(column, '1 = 0', []); // Always false
      return this;
    }
    final preparedValues = values.map(_prepareValue).toList();
    final placeholders = List.filled(preparedValues.length, '?').join(', ');
    _addColumnCondition(
      column,
      '$_colToken IN ($placeholders)',
      preparedValues,
    );
    return this;
  }

  /// Adds NOT IN condition: `column NOT IN (?, ?, ...)`
  ///
  /// **Example:**
  /// ```dart
  /// where.notInList('role', ['admin', 'superuser']);
  /// // Produces: role NOT IN (?, ?)
  /// // Args: ['admin', 'superuser']
  /// ```
  WhereBuilder notInList(Object column, List<Object?> values) {
    _validate(column);
    if (values.isEmpty) return this; // No restriction
    final preparedValues = values.map(_prepareValue).toList();
    final placeholders = List.filled(preparedValues.length, '?').join(', ');
    _addColumnCondition(
      column,
      '$_colToken NOT IN ($placeholders)',
      preparedValues,
    );
    return this;
  }

  // =======================================================
  // NULL CHECKS (IS NULL, IS NOT NULL)
  // =======================================================

  /// Adds IS NULL condition: `column IS NULL`
  ///
  /// **Example:**
  /// ```dart
  /// where.isNull('deleted_at');
  /// // Produces: deleted_at IS NULL
  /// ```
  WhereBuilder isNull(Object column) {
    _validate(column);
    _addColumnCondition(column, '$_colToken IS NULL', []);
    return this;
  }

  /// Adds IS NOT NULL condition: `column IS NOT NULL`
  ///
  /// **Example:**
  /// ```dart
  /// where.isNotNull('email');
  /// // Produces: email IS NOT NULL
  /// ```
  WhereBuilder isNotNull(Object column) {
    _validate(column);
    _addColumnCondition(column, '$_colToken IS NOT NULL', []);
    return this;
  }

  // =======================================================
  // BOOLEAN OPERATIONS (TRUE, FALSE)
  // =======================================================

  /// Adds true condition: `column = 1` (boolean stored as 1/0)
  ///
  /// **Example:**
  /// ```dart
  /// where.isTrue('is_active');
  /// // Produces: is_active = 1
  /// ```
  WhereBuilder isTrue(Object column) {
    _validate(column);
    _addColumnCondition(column, '$_colToken = 1', []);
    return this;
  }

  /// Adds false condition: `column = 0` (boolean stored as 1/0)
  ///
  /// **Example:**
  /// ```dart
  /// where.isFalse('is_deleted');
  /// // Produces: is_deleted = 0
  /// ```
  WhereBuilder isFalse(Object column) {
    _validate(column);
    _addColumnCondition(column, '$_colToken = 0', []);
    return this;
  }

  // =======================================================
  // LOGICAL GROUPS (AND/OR NESTING)
  // =======================================================

  /// Creates an AND group with nested conditions
  ///
  /// **Arguments are collected in the order they appear in the group.**
  ///
  /// **Example:**
  /// ```dart
  /// where
  ///   .eq('country', 'Bulgaria')
  ///   .andGroup((wg) {
  ///     wg.gt('age', 18).lt('age', 65);
  ///   })
  ///   .eq('is_verified', 1);
  ///
  /// // Produces: country = ? AND (age > ? AND age < ?) AND is_verified = ?
  /// // Args: ['Bulgaria', 18, 65, 1] ← Correct order!
  /// ```
  WhereBuilder andGroup(void Function(WhereBuilder) builder) {
    final group = WhereBuilder();
    builder(group);

    if (group._conditions.isEmpty) return this;

    _addBuilder(group);
    return this;
  }

  /// Creates an OR group with nested conditions
  ///
  /// **Example:**
  /// ```dart
  /// where
  ///   .eq('is_active', 1)
  ///   .orGroup((wg) {
  ///     wg.eq('city', 'Sofia').eq('city', 'Plovdiv');
  ///   });
  ///
  /// // Produces: is_active = ? AND (city = ? OR city = ?)
  /// // Args: [1, 'Sofia', 'Plovdiv'] ← Correct order!
  /// ```
  WhereBuilder orGroup(void Function(WhereBuilder) builder) {
    final group = WhereBuilder(separator: 'OR');
    builder(group);

    if (group._conditions.isEmpty) return this;

    _addBuilder(group);
    return this;
  }

  // =======================================================
  // RAW SQL CONDITIONS (USE WITH CAUTION)
  // =======================================================

  /// Adds raw SQL condition (escape hatch for complex cases)
  ///
  /// **Warning:** Use only when necessary. Validate inputs carefully.
  /// Placeholder count must match arguments length.
  ///
  /// **Example:**
  /// ```dart
  /// where.raw('LENGTH(name) > ?', [3]);
  /// // Produces: LENGTH(name) > ?
  /// // Args: [3]
  /// ```
  WhereBuilder raw(String condition, [List<Object?>? args]) {
    if (condition.isEmpty) return this;

    final questionCount = '?'.allMatches(condition).length;
    if (args != null && args.length != questionCount) {
      throw ArgumentError(
        'Placeholder/argument mismatch in raw condition. '
        'Expected $questionCount arguments, got ${args.length}. '
        'Condition: $condition',
      );
    }

    final preparedArgs = args?.map(_prepareValue).toList() ?? [];
    _addRawCondition(condition, preparedArgs);
    _extractColumnsFromRaw(condition);

    return this;
  }

  // =======================================================
  // DATE/TIME SPECIALIZED METHODS
  // =======================================================

  /// Adds date-only equality (ignores time part): `DATE(column) = ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.dateOnlyEq('created_at', DateTime(2024, 1, 15));
  /// // Produces: DATE(created_at) = ?
  /// // Args: ['2024-01-15']
  /// ```
  WhereBuilder dateOnlyEq(Object column, DateTime date) {
    _validate(column);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    _addColumnCondition(column, 'DATE($_colToken) = ?', [dateStr]);
    return this;
  }

  /// Adds date-only greater-than: `DATE(column) > ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.dateOnlyGt('birth_date', DateTime(2000, 1, 1));
  /// // Produces: DATE(birth_date) > ?
  /// // Args: ['2000-01-01']
  /// ```
  WhereBuilder dateOnlyGt(Object column, DateTime date) {
    _validate(column);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    _addColumnCondition(column, 'DATE($_colToken) > ?', [dateStr]);
    return this;
  }

  /// Adds date-only less-than: `DATE(column) < ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.dateOnlyLt('expiry_date', DateTime(2025, 12, 31));
  /// // Produces: DATE(expiry_date) < ?
  /// // Args: ['2025-12-31']
  /// ```
  WhereBuilder dateOnlyLt(Object column, DateTime date) {
    _validate(column);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    _addColumnCondition(column, 'DATE($_colToken) < ?', [dateStr]);
    return this;
  }

  /// Adds date-only between range: `DATE(column) BETWEEN ? AND ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.dateOnlyBetween('created_at',
  ///   DateTime(2024, 1, 1),
  ///   DateTime(2024, 12, 31)
  /// );
  /// // Produces: DATE(created_at) BETWEEN ? AND ?
  /// // Args: ['2024-01-01', '2024-12-31']
  /// ```
  WhereBuilder dateOnlyBetween(Object column, DateTime from, DateTime to) {
    _validate(column);
    final fromStr =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-'
        '${from.day.toString().padLeft(2, '0')}';
    final toStr =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-'
        '${to.day.toString().padLeft(2, '0')}';
    _addColumnCondition(column, 'DATE($_colToken) BETWEEN ? AND ?', [
      fromStr,
      toStr,
    ]);
    return this;
  }

  /// Adds time-only equality (ignores date part): `TIME(column) = ?`
  ///
  /// **Example:**
  /// ```dart
  /// where.timeOnlyEq('created_at', DateTime(2024, 1, 1, 14, 30));
  /// // Produces: TIME(created_at) = ?
  /// // Args: ['14:30:00']
  /// ```
  WhereBuilder timeOnlyEq(Object column, DateTime time) {
    _validate(column);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
    _addColumnCondition(column, 'TIME($_colToken) = ?', [timeStr]);
    return this;
  }

  // =======================================================
  // BUILDER OUTPUT & UTILITIES
  // =======================================================

  /// Builds the complete WHERE clause string
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilder()
  ///   .eq('status', 'active')
  ///   .gt('age', 18);
  ///
  /// print(where.build()); // "status = ? AND age > ?"
  /// ```
  String build([SqlDialect dialect = const NoEscapeDialect()]) {
    return _buildWithDialect(dialect, ParamIndex());
  }

  String _buildWithDialect(SqlDialect dialect, ParamIndex paramIndex) {
    final parts = <String>[];

    for (final condition in _conditions) {
      final compiled = condition.compile(dialect, paramIndex);
      if (compiled.isNotEmpty) {
        parts.add(compiled);
      }
    }

    return parts.join(" $_separator ");
  }

  /// Gets all argument values in order for placeholders
  ///
  /// **Arguments are collected in the exact order conditions were added.**
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilder()
  ///   .eq('status', 'active')
  ///   .andGroup((wg) {
  ///     wg.gt('age', 18).lt('age', 65);
  ///   });
  ///
  /// print(where.args); // ['active', 18, 65]
  /// ```
  List<Object?> get args {
    final allArgs = <Object?>[];

    for (final condition in _conditions) {
      // Nested groups recursively expose their builder's args
      allArgs.addAll(condition.args);
    }

    return List.unmodifiable(allArgs);
  }

  /// Creates a deep copy of this WhereBuilder
  ///
  /// **Example:**
  /// ```dart
  /// final original = WhereBuilder().eq('status', 'active');
  /// final copy = original.copy();
  /// copy.eq('is_verified', 1);
  ///
  /// // original still has only 'status' condition
  /// // copy has both 'status'AND'is_verified' conditions
  /// ```
  WhereBuilder copy() {
    final copy = WhereBuilder(separator: _separator);

    for (final condition in _conditions) {
      switch (condition) {
        case _ColumnCondition(:final column, :final template, :final args):
          copy._conditions.add(
            _ColumnCondition(column, template, List.of(args)),
          );
        case _RawCondition(:final sql, :final args):
          copy._conditions.add(_RawCondition(sql, List.of(args)));
        case _GroupCondition(:final builder):
          copy._conditions.add(_GroupCondition(builder.copy()));
      }
    }
    copy._usedColumns.addAll(_usedColumns);

    return copy;
  }

  /// Creates a deep copy of this WhereBuilder (alias for [copy])
  WhereBuilder clone() => copy();

  /// Checks if a column is referenced in any condition
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilder()
  ///   .eq('status', 'active')
  ///   .gt('age', 18);
  ///
  /// print(where.hasConditionOn('status')); // true
  /// print(where.hasConditionOn('email'));  // false
  /// ```
  bool hasConditionOn(String column) {
    return _usedColumns.contains(column);
  }

  /// Returns read-only set of all columns used in conditions
  ///
  /// **Example:**
  /// ```dart
  /// final columns = where.usedColumns;
  /// print(columns); // {'status', 'age'}
  /// ```
  Set<String> get usedColumns => Set.unmodifiable(_usedColumns);

  /// Checks if builder has no conditions
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilder();
  /// print(where.isEmpty); // true
  ///
  /// where.eq('status', 'active');
  /// print(where.isEmpty); // false
  /// ```
  bool get isEmpty => _conditions.isEmpty;

  /// Checks if builder has conditions
  bool get isNotEmpty => _conditions.isNotEmpty;

  // =======================================================
  // DEBUG UTILITIES
  // =======================================================

  /// Prints the structure of the builder for debugging
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilder()
  ///   .eq('status', 'active')
  ///   .andGroup((wg) {
  ///     wg.gt('age', 18).lt('age', 65);
  ///   });
  ///
  /// where.debugPrint();
  /// // Output:
  /// // WhereBuilder:
  /// //   Separator: " AND "
  /// //   Conditions: 2
  /// //   Used columns: {status, age}
  /// //   Built SQL: "status = ? AND (age > ? AND age < ?)"
  /// //   Args: ['active', 18, 65]
  /// ```
  void debugPrint([String indent = '']) {
    log('${indent}WhereBuilder:', name: ">");
    log('$indent  Separator: "$_separator"', name: ">");
    log('$indent  Conditions: ${_conditions.length}', name: ">");
    log('$indent  Used columns: $_usedColumns', name: ">");
    log('$indent  Built SQL: "${build()}"', name: ">");
    log('$indent  Args: $args', name: ">");

    for (var i = 0; i < _conditions.length; i++) {
      final condition = _conditions[i];
      switch (condition) {
        case _ColumnCondition(:final column, :final template):
          final sql = template.replaceAll(_colToken, column.toString());
          log('$indent  [$i] Condition: "$sql"', name: ">");
          if (condition.args.isNotEmpty) {
            log('$indent      Args: ${condition.args}', name: ">");
          }
        case _RawCondition(:final sql):
          log('$indent  [$i] Raw condition: "$sql"', name: ">");
          if (condition.args.isNotEmpty) {
            log('$indent      Args: ${condition.args}', name: ">");
          }
        case _GroupCondition(:final builder):
          log('$indent  [$i] Nested Builder:', name: ">");
          builder.debugPrint('$indent    ');
      }
    }
  }
}
