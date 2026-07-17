import 'package:drift/drift.dart';

part 'drift_db.g.dart';

/// Users table (drift).
class DUsers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get age => integer()();
  BoolColumn get active => boolean()();
}

/// Posts table (drift), FK to users.
class DPosts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get title => text()();
}

/// Minimal drift database with the two benchmark tables.
@DriftDatabase(tables: [DUsers, DPosts])
class DriftDb extends _$DriftDb {
  DriftDb(super.e);

  @override
  int get schemaVersion => 1;
}
