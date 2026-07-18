import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:vm_service/vm_service.dart';

/// One query event received from a `phorm.queryBatch` batch.
class QueryLogEntry {
  QueryLogEntry(this.json);

  final Map<String, dynamic> json;

  int get id => json['id'] as int;
  String get sql => json['sql'] as String? ?? '';
  String? get parameters => json['parameters'] as String?;
  double get executionTimeMs =>
      (json['executionTimeMs'] as num?)?.toDouble() ?? 0;
  bool get isSlow => json['isSlow'] as bool? ?? false;
  String? get error => json['error'] as String?;
  String get dbId => json['dbId'] as String? ?? 'main';
}

/// Thin typed client over the `ext.phorm.*` service extensions registered
/// by the `phorm_devtools` bridge in the debugged application.
class PhormService {
  PhormService._();

  /// Shared instance for the whole panel.
  static final PhormService instance = PhormService._();

  final StreamController<QueryLogEntry> _queries =
      StreamController<QueryLogEntry>.broadcast();
  StreamSubscription<Event>? _eventSub;

  /// Live feed of executed queries.
  Stream<QueryLogEntry> get queryStream => _queries.stream;

  /// Starts listening to `phorm.*` extension events.
  void startListening() {
    _eventSub ??= serviceManager.service?.onExtensionEvent.listen((event) {
      if (event.extensionKind == 'phorm.queryBatch') {
        final events = event.extensionData?.data['events'] as List? ?? [];
        for (final e in events) {
          _queries.add(QueryLogEntry((e as Map).cast<String, dynamic>()));
        }
      }
    });
  }

  Future<Map<String, dynamic>> _call(
    String method, [
    Map<String, String>? args,
  ]) async {
    final response = await serviceManager.callServiceExtensionOnMainIsolate(
      'ext.phorm.$method',
      args: args ?? const {},
    );
    final json = response.json ?? const {};
    final error = json['error'];
    if (error is Map) {
      throw StateError('${error['code']}: ${error['message']}');
    }
    return json.cast<String, dynamic>();
  }

  /// `ext.phorm.getInfo`
  Future<Map<String, dynamic>> getInfo() => _call('getInfo');

  /// `ext.phorm.listDatabases`
  Future<List<Map<String, dynamic>>> listDatabases() async {
    final result = await _call('listDatabases');
    return (result['databases'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  /// `ext.phorm.getTables`
  Future<List<Map<String, dynamic>>> getTables(String dbId) async {
    final result = await _call('getTables', {'dbId': dbId});
    return (result['tables'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  /// `ext.phorm.queryData`
  Future<Map<String, dynamic>> queryData({
    required String dbId,
    required String table,
    int limit = 50,
    int offset = 0,
    bool includeDeleted = false,
    String? searchQuery,
    String? orderBy,
    String orderDir = 'asc',
  }) =>
      _call('queryData', {
        'dbId': dbId,
        'table': table,
        'limit': '$limit',
        'offset': '$offset',
        'includeDeleted': '$includeDeleted',
        if (searchQuery != null && searchQuery.isNotEmpty)
          'searchQuery': searchQuery,
        'orderBy': ?orderBy,
        'orderDir': orderDir,
      });

  /// `ext.phorm.getMigrations`
  Future<Map<String, dynamic>> getMigrations(String dbId) =>
      _call('getMigrations', {'dbId': dbId});

  /// `ext.phorm.getActiveStreams`
  Future<List<Map<String, dynamic>>> getActiveStreams(String dbId) async {
    final result = await _call('getActiveStreams', {'dbId': dbId});
    return (result['streams'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  /// Releases event subscriptions.
  void dispose() {
    _eventSub?.cancel();
    _queries.close();
  }
}
