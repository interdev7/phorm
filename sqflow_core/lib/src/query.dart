import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

import 'core.dart';
import 'sort_builder.dart';
import 'where_builder.dart';

/// A fluent query builder for SQFlow models.
/// Allows chaining conditions, sorting, and pagination.
class SqflowQuery<T extends Model> {
  final SqflowCore<T> service;
  final WhereBuilder _where = WhereBuilder();
  SortBuilder? _sort;
  int _limit = 20;
  int _offset = 0;
  List<Includable>? _include;
  Attributes? _attributes;
  bool _withDeleted = false;

  SqflowQuery(this.service);

  /// Adds a condition to the query.
  ///
  /// **Example:**
  /// ```dart
  /// Posts.where(PostTable.title.like('%Flutter%'))
  /// ```
  SqflowQuery<T> where(SqflowCondition condition) {
    if (condition.operator == 'IS NULL') {
      _where.isNull(condition.column);
    } else if (condition.operator == 'IS NOT NULL') {
      _where.isNotNull(condition.column);
    } else if (condition.operator == 'IN') {
      _where.inList(condition.column, condition.value as List);
    } else if (condition.operator == 'LIKE') {
      _where.like(condition.column, condition.value as String);
    } else {
      // Basic operators (=, !=, >, <, >=, <=)
      _applyOperator(condition);
    }
    return this;
  }

  void _applyOperator(SqflowCondition condition) {
    final Object col = condition.column;
    final Object? val = condition.value;
    if (val == null) return;

    switch (condition.operator) {
      case '=':
        _where.eq(col, val);
        break;
      case '!=':
        _where.ne(col, val);
        break;
      case '>':
        _where.gt(col, val);
        break;
      case '>=':
        _where.gte(col, val);
        break;
      case '<':
        _where.lt(col, val);
        break;
      case '<=':
        _where.lte(col, val);
        break;
    }
  }

  /// Adds an ORDER BY clause.
  SqflowQuery<T> orderBy(SqflowColumn<dynamic> column,
      {bool descending = false}) {
    _sort ??= SortBuilder();
    if (descending) {
      _sort!.desc(column.name);
    } else {
      _sort!.asc(column.name);
    }
    return this;
  }

  /// Sets the max results.
  SqflowQuery<T> limit(int count) {
    _limit = count;
    return this;
  }

  /// Sets the number of rows to skip.
  SqflowQuery<T> offset(int count) {
    _offset = count;
    return this;
  }

  /// Eager-loads relationships.
  SqflowQuery<T> include(List<Includable> relations) {
    _include = relations;
    return this;
  }

  /// Selects specific columns.
  SqflowQuery<T> attributes(Attributes attr) {
    _attributes = attr;
    return this;
  }

  /// Includes soft-deleted records.
  SqflowQuery<T> withDeleted() {
    _withDeleted = true;
    return this;
  }

  /// Executes the query and returns a list of models.
  Future<List<T>> get() async {
    final result = await service.readAll(
      where: _where.isEmpty ? null : _where,
      sort: _sort,
      limit: _limit,
      offset: _offset,
      include: _include,
      attributes: _attributes,
      withDeleted: _withDeleted,
    );
    return result.data;
  }

  /// Executes the query and returns the first result, or null.
  Future<T?> first() async {
    final results = await limit(1).get();
    return results.isEmpty ? null : results.first;
  }
}
