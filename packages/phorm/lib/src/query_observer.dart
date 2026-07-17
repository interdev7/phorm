// =======================================================
// QUERY OBSERVER 📊
// =======================================================

/// A single executed database operation, reported to a [QueryObserver].
///
/// Produced by the database manager for every CRUD/SQL action it runs
/// (the same instrumentation point that powers query logging), including
/// failed ones. Use it to feed metrics, tracing or crash reporting.
final class QueryEvent {
  /// Creates an event describing one executed operation.
  const QueryEvent({
    required this.sql,
    required this.duration,
    this.arguments,
    this.isSlow = false,
    this.error,
    this.stackTrace,
  });

  /// The executed SQL, or a short action label for high-level operations
  /// (e.g. `SOFT DELETE users`).
  final String sql;

  /// Bound arguments of the statement, if any.
  final List<Object?>? arguments;

  /// Wall-clock execution time of the operation.
  final Duration duration;

  /// Whether [duration] exceeded the database's slow-query threshold.
  final bool isSlow;

  /// The error thrown by the operation, or `null` when it succeeded.
  final Object? error;

  /// Stack trace accompanying [error], if the operation failed.
  final StackTrace? stackTrace;

  /// Whether the operation failed.
  bool get failed => error != null;

  @override
  String toString() {
    final status =
        failed
            ? 'failed: $error'
            : isSlow
            ? 'slow'
            : 'ok';
    return 'QueryEvent($sql, ${duration.inMilliseconds}ms, $status)';
  }
}

/// Callback invoked for every database operation.
///
/// Keep it fast and non-throwing: it runs synchronously on the query path.
typedef QueryObserver = void Function(QueryEvent event);
