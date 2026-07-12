import 'package:phorm/phorm.dart';

// =======================================================
// EXTENSION: WHERE BUILDER CONVENIENCE METHODS
// =======================================================

/// Extension methods for common WhereBuilder patterns
extension WhereBuilderExtensions on WhereBuilder {
  /// Adds condition only if value is not null and not empty string
  ///
  /// **Example:**
  /// ```dart
  /// where.eqIfNotNull(Users.name, searchName);
  /// // Only adds condition if searchName is not null and not empty
  /// ```
  WhereBuilder eqIfNotNull(Object column, String? value) {
    if (value != null && value.isNotEmpty) {
      return eq(column, value);
    }
    return this;
  }

  /// Adds IN condition only if list is not null and not empty
  ///
  /// **Example:**
  /// ```dart
  /// where.inListIfNotEmpty(Users.role, selectedRoles);
  /// // Only adds condition if selectedRoles has items
  /// ```
  WhereBuilder inListIfNotEmpty(Object column, List<Object?>? values) {
    if (values != null && values.isNotEmpty) {
      return inList(column, values);
    }
    return this;
  }

  /// Adds date range if both from and to are provided,
  /// or single bound if only one is provided
  ///
  /// **Example:**
  /// ```dart
  /// where.dateRangeIfProvided(Users.createdAt, startDate, endDate);
  /// ```
  WhereBuilder dateRangeIfProvided(
    Object column,
    DateTime? from,
    DateTime? to,
  ) {
    if (from != null && to != null) {
      return between(column, from, to);
    } else if (from != null) {
      return gte(column, from);
    } else if (to != null) {
      return lte(column, to);
    }
    return this;
  }

  /// Adds a condition only if [condition] is true.
  ///
  /// **Example:**
  /// ```dart
  /// where.addIf(onlyActive, (w) => w.isTrue(Users.isActive));
  /// ```
  WhereBuilder addIf(
    bool condition,
    WhereBuilder Function(WhereBuilder builder) builderFunc,
  ) {
    if (condition) {
      return builderFunc(this);
    }
    return this;
  }

  /// Adds a condition only if [value] is not null.
  ///
  /// **Example:**
  /// ```dart
  /// where.addNotNull(searchQuery, (w, val) => w.like(Users.name, '%$val%'));
  /// ```
  WhereBuilder addNotNull<V>(
    V? value,
    WhereBuilder Function(WhereBuilder builder, V value) builderFunc,
  ) {
    if (value != null) {
      return builderFunc(this, value);
    }
    return this;
  }
}

// =======================================================
// FACTORY: COMMON WHERE BUILDER PATTERNS
// =======================================================

/// Factory functions for common WhereBuilder patterns
class WhereBuilders {
  /// Creates a WHERE clause for soft-delete aware queries
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilders.softDelete(
  ///   paranoid: true,
  ///   withDeleted: false,
  ///   onlyDeleted: false,
  /// );
  /// // Produces: deleted_at IS NULL
  /// ```
  static WhereBuilder softDelete({
    required bool paranoid,
    bool withDeleted = false,
    bool onlyDeleted = false,
  }) {
    final where = WhereBuilder();

    if (paranoid) {
      if (onlyDeleted) {
        where.isNotNull('deleted_at');
      } else if (!withDeleted) {
        where.isNull('deleted_at');
      }
    }

    return where;
  }

  /// Creates WHERE clause for text search across multiple columns
  ///
  /// **Example:**
  /// ```dart
  /// final where = WhereBuilders.multiColumnSearch(
  ///   'john',
  ///   ['first_name', 'last_name', 'email'],
  ///   caseSensitive: false,
  /// );
  /// // Produces: (LOWER(first_name) LIKE LOWER(?)
  /// //            OR LOWER(last_name) LIKE LOWER(?)
  /// //            OR LOWER(email) LIKE LOWER(?))
  /// // Args: ['%john%', '%john%', '%john%']
  /// ```
  static WhereBuilder multiColumnSearch(
    String query,
    List<String> columns, {
    bool caseSensitive = false,
  }) {
    final where = WhereBuilder();

    if (query.isNotEmpty && columns.isNotEmpty) {
      where.orGroup((og) {
        final searchPattern = '%$query%';
        for (final column in columns) {
          if (caseSensitive) {
            og.like(column, searchPattern);
          } else {
            og.ilike(column, searchPattern);
          }
        }
      });
    }

    return where;
  }
}
