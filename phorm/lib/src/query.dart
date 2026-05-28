import 'package:phorm_annotations/phorm_annotations.dart';

import 'core.dart';
import 'sort_builder.dart';
import 'where_builder.dart';

/// A fluent query builder for PHORM models.
/// Allows chaining conditions, sorting, and pagination.
class PhormQuery<T extends Model> {
  final PhormCore<T> service;
  final WhereBuilder _where = WhereBuilder();
  SortBuilder? _sort;
  int _limit = 20;
  int _offset = 0;
  List<Includable>? _include;
  Attributes? _attributes;
  bool _withDeleted = false;

  PhormQuery(this.service);

  /// Adds a condition to the query.
  ///
  /// **Example:**
  /// ```dart
  /// Posts.where(PostTable.title.like('%Flutter%'))
  /// ```
  PhormQuery<T> where(PhormCondition condition) {
    switch (condition.operator) {
      case 'IS NULL':
        _where.isNull(condition.column);
      case 'IS NOT NULL':
        _where.isNotNull(condition.column);
      case 'IN':
        _where.inList(condition.column, condition.value as List);
      case 'NOT IN':
        _where.notInList(condition.column, condition.value as List);
      case 'LIKE':
        _where.like(condition.column, condition.value as String);
      case 'NOT LIKE':
        _where.notLike(condition.column, condition.value as String);
      case 'ILIKE':
        _where.ilike(condition.column, condition.value as String);
      case 'NOT ILIKE':
        _where.notIlike(condition.column, condition.value as String);
      case 'REGEXP':
        _where.regexp(condition.column, condition.value as String);
      case 'BETWEEN':
        final range = condition.value as List;
        _where.between(
            condition.column, range[0] as Object, range[1] as Object);
      case 'NOT BETWEEN':
        final range = condition.value as List;
        _where.notBetween(
            condition.column, range[0] as Object, range[1] as Object);
      case 'STARTS WITH':
        _where.startsWith(condition.column, condition.value as String);
      case 'ENDS WITH':
        _where.endsWith(condition.column, condition.value as String);
      case 'TRUE':
        _where.isTrue(condition.column);
      case 'FALSE':
        _where.isFalse(condition.column);
      case 'LENGTH =':
        _where.lengthEq(condition.column, condition.value as int);
      case 'LENGTH !=':
        _where.lengthNe(condition.column, condition.value as int);
      case 'LENGTH >':
        _where.lengthGt(condition.column, condition.value as int);
      case 'LENGTH >=':
        _where.lengthGte(condition.column, condition.value as int);
      case 'LENGTH <':
        _where.lengthLt(condition.column, condition.value as int);
      case 'LENGTH <=':
        _where.lengthLte(condition.column, condition.value as int);
      case 'SUBSTR =':
        final s = condition.value as List;
        _where.substrEq(
            condition.column, s[0] as int, s[1] as int, s[2] as String);
      case 'SUBSTR LIKE':
        final s = condition.value as List;
        _where.substrLike(
            condition.column, s[0] as int, s[1] as int, s[2] as String);
      case 'SUBSTR ILIKE':
        final s = condition.value as List;
        _where.substrIlike(
            condition.column, s[0] as int, s[1] as int, s[2] as String);
      case 'DATE =':
        _where.dateOnlyEq(condition.column, condition.value as DateTime);
      case 'DATE >':
        _where.dateOnlyGt(condition.column, condition.value as DateTime);
      case 'DATE <':
        _where.dateOnlyLt(condition.column, condition.value as DateTime);
      case 'DATE BETWEEN':
        final d = condition.value as List;
        _where.dateOnlyBetween(
            condition.column, d[0] as DateTime, d[1] as DateTime);
      case 'TIME =':
        _where.timeOnlyEq(condition.column, condition.value as DateTime);
      default:
        // Basic operators (=, !=, >, <, >=, <=)
        _applyOperator(condition);
    }
    return this;
  }

  /// Adds a condition to the query only if the provided boolean [flag] is true.
  ///
  /// **Example:**
  /// ```dart
  /// query.whereIf(onlyActive, () => Users.isActive.isTrue())
  /// ```
  PhormQuery<T> whereIf(bool flag, PhormCondition Function() conditionBuilder) {
    if (flag) {
      where(conditionBuilder());
    }
    return this;
  }

  /// Adds a condition to the query only if the provided [value] is not null.
  ///
  /// **Example:**
  /// ```dart
  /// query.whereNotNull(searchQuery, (val) => Users.name.like('%$val%'))
  /// ```
  PhormQuery<T> whereNotNull<V>(
      V? value, PhormCondition Function(V value) conditionBuilder) {
    if (value != null) {
      where(conditionBuilder(value));
    }
    return this;
  }

  void _applyOperator(PhormCondition condition) {
    final Object col = condition.column;
    final Object? val = condition.value;
    if (val == null) return;

    switch (condition.operator) {
      case '=':
        _where.eq(col, val);
      case '!=':
        _where.ne(col, val);
      case '>':
        _where.gt(col, val);
      case '>=':
        _where.gte(col, val);
      case '<':
        _where.lt(col, val);
      case '<=':
        _where.lte(col, val);
    }
  }

  /// Adds an ORDER BY clause.
  PhormQuery<T> orderBy(PhormColumn<dynamic> column,
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
  PhormQuery<T> limit(int count) {
    _limit = count;
    return this;
  }

  /// Sets the number of rows to skip.
  PhormQuery<T> offset(int count) {
    _offset = count;
    return this;
  }

  /// Eager-loads relationships.
  PhormQuery<T> include(List<Includable> relations) {
    _include = relations;
    return this;
  }

  /// Eager-loads a single relationship.
  PhormQuery<T> includeOne(Includable relation) {
    _include ??= [];
    _include!.add(relation);
    return this;
  }

  /// Selects specific columns.
  PhormQuery<T> attributes(Attributes attr) {
    _attributes = attr;
    return this;
  }

  /// Includes soft-deleted records.
  PhormQuery<T> withDeleted() {
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

  /// Executes the query and returns the total count of matching rows.
  ///
  /// **Example:**
  /// ```dart
  /// final activeCount = await Users.query.where(Users.isActive.isTrue()).count();
  /// ```
  Future<int> count({Object? column}) async {
    return service.count(
      column: column,
      where: _where.isEmpty ? null : _where,
    );
  }

  /// Calculates the sum of a specific column.
  Future<num> sum(Object column) async {
    return service.sum(
      column,
      where: _where.isEmpty ? null : _where,
    );
  }

  /// Calculates the average of a specific column.
  Future<num> avg(Object column) async {
    return service.avg(
      column,
      where: _where.isEmpty ? null : _where,
    );
  }

  /// Finds the minimum value of a specific column.
  Future<num> min(Object column) async {
    return service.min(
      column,
      where: _where.isEmpty ? null : _where,
    );
  }

  /// Finds the maximum value of a specific column.
  Future<num> max(Object column) async {
    return service.max(
      column,
      where: _where.isEmpty ? null : _where,
    );
  }

  /// Executes the query and returns both the current page of results and the total count.
  ///
  /// **Example:**
  /// ```dart
  /// final result = await Users.query.limit(10).getWithCount();
  /// print('Fetched ${result.data.length} of ${result.count}');
  /// ```
  Future<ResultWithCount<T>> getWithCount() async {
    return service.readAllWithCount(
      where: _where.isEmpty ? null : _where,
      sort: _sort,
      limit: _limit,
      offset: _offset,
      include: _include,
      attributes: _attributes,
      withDeleted: _withDeleted,
    );
  }

  /// Compiles and returns the SQL string for this query.
  String toSql() {
    return service.getBuildJoinQuery(
      where: _where.isEmpty ? null : _where,
      sort: _sort,
      limit: _limit,
      offset: _offset,
      include: _include,
      attributes: _attributes,
    );
  }
}
