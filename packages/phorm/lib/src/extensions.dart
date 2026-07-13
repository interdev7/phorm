import 'package:phorm_annotations/phorm_annotations.dart';

import 'core.dart';
import 'database_interface.dart';

/// Convenience helpers on [PhormDatabase] for resolving model services.
extension PhormDatabaseServiceExtension on PhormDatabase {
  /// Resolves and creates a PhormCore service for the given Model type [T].
  PhormCore<T> service<T extends Model>() {
    final table = tables.where((t) => t.type == T).firstOrNull;
    if (table == null) {
      throw StateError('Table for type $T is not registered in this DB');
    }
    return PhormCore<T>(dbManager: this, table: table as Table<T>);
  }
}
