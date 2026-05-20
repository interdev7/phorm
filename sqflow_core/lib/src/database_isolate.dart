// Conditional import router:
//   - Flutter Web  → database_isolate_web.dart  (WasmSqlite3)
//   - All others   → database_isolate_io.dart   (dart:isolate + sqlite3 native)
//
// All consumers just import THIS file and call createDatabaseIsolate().
// No conditional logic is needed anywhere else in the project.
export 'database_isolate_common.dart';

export 'database_isolate_io.dart'
    if (dart.library.js_interop) 'database_isolate_web.dart';
