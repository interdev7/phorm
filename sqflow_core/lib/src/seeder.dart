import 'package:sqflow_core/sqflow_core.dart';

/// Interface for database seeders.
/// Use this to populate the database with initial or test data.
abstract class Seeder {
  /// Executes the seeding logic.
  Future<void> run(SqflowDatabase db);
}
