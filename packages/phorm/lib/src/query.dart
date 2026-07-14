import 'package:phorm_annotations/phorm_annotations.dart';

import 'core.dart';
import 'sort_builder.dart';
import 'where_builder.dart';

/// A fluent query builder for PHORM models.
/// Allows chaining conditions, sorting, and pagination.
class PhormQuery<T extends Model> {
  /// The service the query executes against.
  final PhormCore<T> service;
  final WhereBuilder _where = WhereBuilder();
  SortBuilder? _sort;
  int? _limit = 20;
  int _offset = 0;
  List<Includable>? _include;
  Attributes? _attributes;
  bool _withDeleted = false;
  bool _distinct = false;
  List<String>? _groupBy;
  WhereBuilder? _having;

  /// Creates a query bound to [service].
  PhormQuery(this.service);

  /// Adds a condition to the query.
  ///
  /// **Example:**
  /// ```dart
  /// Posts.where(PostTable.title.like('%Flutter%'))
  /// ```
  PhormQuery<T> where(PhormCondition condition) {
    _applyCondition(_where, condition);
    return this;
  }

  /// Applies [condition] to [wb], recursing into `&`/`|` groups.
  void _applyCondition(WhereBuilder wb, PhormCondition condition) {
    if (condition is PhormConditionGroup) {
      void applyAll(WhereBuilder group) {
        for (final child in condition.conditions) {
          _applyCondition(group, child);
        }
      }

      if (condition.isOr) {
        wb.orGroup(applyAll);
      } else {
        wb.andGroup(applyAll);
      }
      return;
    }

    switch (condition.operator) {
      case 'IS NULL':
        wb.isNull(condition.column);
      case 'IS NOT NULL':
        wb.isNotNull(condition.column);
      case 'IN':
        wb.inList(condition.column, condition.value as List);
      case 'NOT IN':
        wb.notInList(condition.column, condition.value as List);
      case 'LIKE':
        wb.like(condition.column, condition.value as String);
      case 'NOT LIKE':
        wb.notLike(condition.column, condition.value as String);
      case 'ILIKE':
        wb.ilike(condition.column, condition.value as String);
      case 'NOT ILIKE':
        wb.notIlike(condition.column, condition.value as String);
      case 'REGEXP':
        wb.regexp(condition.column, condition.value as String);
      case 'BETWEEN':
        final range = condition.value as List;
        wb.between(condition.column, range[0] as Object, range[1] as Object);
      case 'NOT BETWEEN':
        final range = condition.value as List;
        wb.notBetween(condition.column, range[0] as Object, range[1] as Object);
      case 'STARTS WITH':
        wb.startsWith(condition.column, condition.value as String);
      case 'ENDS WITH':
        wb.endsWith(condition.column, condition.value as String);
      case 'TRUE':
        wb.isTrue(condition.column);
      case 'FALSE':
        wb.isFalse(condition.column);
      case 'LENGTH =':
        wb.lengthEq(condition.column, condition.value as int);
      case 'LENGTH !=':
        wb.lengthNe(condition.column, condition.value as int);
      case 'LENGTH >':
        wb.lengthGt(condition.column, condition.value as int);
      case 'LENGTH >=':
        wb.lengthGte(condition.column, condition.value as int);
      case 'LENGTH <':
        wb.lengthLt(condition.column, condition.value as int);
      case 'LENGTH <=':
        wb.lengthLte(condition.column, condition.value as int);
      case 'SUBSTR =':
        final s = condition.value as List;
        wb.substrEq(condition.column, s[0] as int, s[1] as int, s[2] as String);
      case 'SUBSTR LIKE':
        final s = condition.value as List;
        wb.substrLike(
          condition.column,
          s[0] as int,
          s[1] as int,
          s[2] as String,
        );
      case 'SUBSTR ILIKE':
        final s = condition.value as List;
        wb.substrIlike(
          condition.column,
          s[0] as int,
          s[1] as int,
          s[2] as String,
        );
      case 'DATE =':
        wb.dateOnlyEq(condition.column, condition.value as DateTime);
      case 'DATE >':
        wb.dateOnlyGt(condition.column, condition.value as DateTime);
      case 'DATE <':
        wb.dateOnlyLt(condition.column, condition.value as DateTime);
      case 'DATE BETWEEN':
        final d = condition.value as List;
        wb.dateOnlyBetween(
          condition.column,
          d[0] as DateTime,
          d[1] as DateTime,
        );
      case 'TIME =':
        wb.timeOnlyEq(condition.column, condition.value as DateTime);
      default:
        // Basic operators (=, !=, >, <, >=, <=)
        _applyOperator(wb, condition);
    }
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
    V? value,
    PhormCondition Function(V value) conditionBuilder,
  ) {
    if (value != null) {
      where(conditionBuilder(value));
    }
    return this;
  }

  void _applyOperator(WhereBuilder wb, PhormCondition condition) {
    final Object col = condition.column;
    final Object? val = condition.value;
    if (val == null) return;

    switch (condition.operator) {
      case '=':
        wb.eq(col, val);
      case '!=':
        wb.ne(col, val);
      case '>':
        wb.gt(col, val);
      case '>=':
        wb.gte(col, val);
      case '<':
        wb.lt(col, val);
      case '<=':
        wb.lte(col, val);
    }
  }

  /// Adds an ORDER BY clause.
  PhormQuery<T> orderBy(
    PhormColumn<dynamic> column, {
    bool descending = false,
  }) {
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

  /// Removes the default limit of 20 rows — the query returns all matches.
  ///
  /// **Example:**
  /// ```dart
  /// final everyone = await Users.query.noLimit().get();
  /// ```
  PhormQuery<T> noLimit() {
    _limit = null;
    return this;
  }

  /// Deduplicates result rows (`SELECT DISTINCT`).
  PhormQuery<T> distinct() {
    _distinct = true;
    return this;
  }

  /// Selects only the given columns (shorthand for
  /// `attributes(Attributes.include([...]))`).
  ///
  /// **Example:**
  /// ```dart
  /// final names = await Users.query.select([Users.firstName, Users.city]).get();
  /// ```
  PhormQuery<T> select(List<Object> columns) {
    _attributes = Attributes.include([
      for (final c in columns) c is PhormColumn ? c.name : c.toString(),
    ]);
    return this;
  }

  /// Groups rows by the given columns (`GROUP BY`).
  ///
  /// Grouped rows are usually not full models — read them with [rows]
  /// together with aggregate expressions selected via [attributes]/[select].
  ///
  /// **Example:**
  /// ```dart
  /// final perCity = await Users.query
  ///     .groupBy([Users.city])
  ///     .having(Users.age.gt(30))
  ///     .rows();
  /// ```
  PhormQuery<T> groupBy(List<Object> columns) {
    _groupBy = [
      for (final c in columns) c is PhormColumn ? c.name : c.toString(),
    ];
    return this;
  }

  /// Adds a HAVING condition for a [groupBy] query.
  PhormQuery<T> having(PhormCondition condition) {
    _having ??= WhereBuilder();
    _applyCondition(_having!, condition);
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
      distinct: _distinct,
    );
    return result.data;
  }

  /// Executes the query and returns raw rows without model mapping.
  ///
  /// Use for [groupBy]/[having] and aggregate selections, where result rows
  /// do not correspond to full models.
  Future<List<Map<String, Object?>>> rows() async {
    return service.readRows(
      where: _where.isEmpty ? null : _where,
      sort: _sort,
      limit: _limit,
      offset: _offset,
      include: _include,
      attributes: _attributes,
      withDeleted: _withDeleted,
      distinct: _distinct,
      groupBy: _groupBy,
      having: _having,
    );
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
    return service.count(column: column, where: _where.isEmpty ? null : _where);
  }

  /// Calculates the sum of a specific column.
  Future<num> sum(Object column) async {
    return service.sum(column, where: _where.isEmpty ? null : _where);
  }

  /// Calculates the average of a specific column.
  Future<num> avg(Object column) async {
    return service.avg(column, where: _where.isEmpty ? null : _where);
  }

  /// Finds the minimum value of a specific column.
  Future<num> min(Object column) async {
    return service.min(column, where: _where.isEmpty ? null : _where);
  }

  /// Finds the maximum value of a specific column.
  Future<num> max(Object column) async {
    return service.max(column, where: _where.isEmpty ? null : _where);
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
      distinct: _distinct,
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
      distinct: _distinct,
      groupBy: _groupBy,
      having: _having,
    );
  }
}
