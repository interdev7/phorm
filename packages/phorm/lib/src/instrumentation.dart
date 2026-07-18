// =======================================================
// INSTRUMENTATION 🔬
// =======================================================

import 'database_interface.dart';
import 'query_observer.dart';

/// Describes one reactive watch stream (`watchOne` / `watchAll`)
/// reported to [PhormInstrumentation].
final class StreamWatchEvent {
  /// Creates a description of an active watch stream.
  const StreamWatchEvent({
    required this.id,
    required this.kind,
    required this.table,
    required this.dependencies,
    this.primaryKey,
  });

  /// Process-unique identifier of the stream instance.
  final int id;

  /// Either `watchOne` or `watchAll`.
  final String kind;

  /// The table the stream primarily watches.
  final String table;

  /// All table names whose changes re-trigger the stream
  /// (the primary table, included relations and extra dependencies).
  final List<String> dependencies;

  /// Primary key value for `watchOne` streams, `null` for `watchAll`.
  final Object? primaryKey;
}

/// Process-wide sink for runtime introspection events, used by developer
/// tooling such as the Phorm Studio DevTools bridge.
///
/// [instance] is `null` unless tooling attaches one, and every call site
/// guards with a single null check — the production hot path pays nothing.
/// Implementations must be fast and non-throwing: callbacks run
/// synchronously on the query/stream path.
abstract interface class PhormInstrumentation {
  /// The active sink, or `null` when no tooling is attached.
  static PhormInstrumentation? instance;

  static int _watchSeq = 0;

  /// Claims the next process-unique watch stream id.
  static int nextWatchId() => ++_watchSeq;

  /// Called after every executed database operation, alongside the
  /// database's own [QueryObserver].
  void queryExecuted(PhormDatabase db, QueryEvent event);

  /// Called when a watch stream gets its first listener.
  void streamCreated(StreamWatchEvent event);

  /// Called on every value emitted by the watch stream [id].
  void streamEmitted(int id);

  /// Called when the watch stream [id] is cancelled or completes.
  void streamDestroyed(int id);
}
