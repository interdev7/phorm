/// Base contract for query results.
abstract class IResult<T> {
  /// The rows returned by the query.
  List<T> data = [];
}

/// A plain list result.
class Result<T> implements IResult<T> {
  /// Creates a result with [data].
  Result({required this.data});

  @override
  List<T> data;
}

/// A result carrying the total row [count] alongside [data].
class ResultWithCount<T> implements IResult<T> {
  /// Total number of matching rows (ignoring pagination).
  final int count;

  /// Creates a counted result.
  ResultWithCount({required this.data, required this.count});

  @override
  List<T> data;
}
