/// Simple interface for database execution to avoid direct dependency on sqlite3
/// in the platform interface. This allows the generator to be pure Dart.
abstract interface class PhormDatabaseExecutor {
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
}
