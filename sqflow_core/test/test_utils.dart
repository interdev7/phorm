import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflow_core/sqflow_core.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:sqflite_common_ffi/sqflite_ffi.dart';
export 'package:sqflow_core/sqflow_core.dart';
export 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

void initSqflite() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

extension SqflowCoreTestExt on SqflowCore {
  String getBuildJoinQuery({
    List<String>? columns,
    Attributes? attributes,
    List<Includable>? include,
    WhereBuilder? where,
    SortBuilder? sort,
    int? limit,
    int? offset,
    bool includeTotalCount = false,
    bool explainQueryPlan = false,
  }) {
    return (this as dynamic).buildJoinQuery(
      columns: columns,
      attributes: attributes,
      include: include,
      where: where,
      sort: sort,
      limit: limit,
      offset: offset,
      includeTotalCount: includeTotalCount,
      explainQueryPlan: explainQueryPlan,
    ) as String;
  }
}
