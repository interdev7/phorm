/// Simple interface for database execution to avoid direct dependency on sqlite3
/// in the platform interface. This allows the generator to be pure Dart.
abstract interface class PhormDatabaseExecutor {
  /// Executes a raw SQL statement without returning rows.
  Future<void> execute(String sql, [List<Object?>? arguments]);

  /// Runs a structured SELECT against [table].
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });

  /// Deletes [table] rows matching [where]; returns the affected count.
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  /// Updates [table] rows matching [where]; returns the affected count.
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// Inserts [values] into [table]; returns the new row id.
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    String? conflictAlgorithm,
  });
}
