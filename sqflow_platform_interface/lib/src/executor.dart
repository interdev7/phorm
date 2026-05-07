/// Simple interface for database execution to avoid direct dependency on sqflite
/// in the platform interface. This allows the generator to be pure Dart.
abstract class SqflowDatabaseExecutor {
  Future<void> execute(String sql, [List<Object?>? arguments]);
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset});
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});
  Future<int> update(String table, Map<String, Object?> values,
      {String? where, List<Object?>? whereArgs});
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, String? conflictAlgorithm});
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]);
  SqflowBatch batch();
  Future<R> transaction<R>(Future<R> Function(SqflowDatabaseExecutor txn) action);
}

abstract class SqflowBatch {
  void insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, String? conflictAlgorithm});
  void update(String table, Map<String, Object?> values,
      {String? where, List<Object?>? whereArgs});
  void delete(String table, {String? where, List<Object?>? whereArgs});
  void execute(String sql, [List<Object?>? arguments]);
  Future<List<Object?>> commit({bool? exclusive, bool? noResult, bool? continueOnError});
}
