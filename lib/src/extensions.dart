import 'package:phorm_annotations/phorm_annotations.dart';

import 'core.dart';
import 'database_interface.dart';

extension SqflowDatabaseServiceExtension on SqflowDatabase {
  /// Resolves and creates a SqflowCore service for the given Model type [T].
  SqflowCore<T> service<T extends Model>() {
    final table = tables.where((t) => t.type == T).firstOrNull;
    if (table == null) {
      throw StateError('Table for type $T is not registered in this DB');
    }
    return SqflowCore<T>(dbManager: this, table: table as Table<T>);
  }
}
