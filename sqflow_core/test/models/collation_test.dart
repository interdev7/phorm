import 'package:sqflow_core/sqflow_core.dart';

part 'collation_test.sql.g.dart';

late DB appDb;

@Schema(tableName: 'collation_tests')
class CollationTest extends Model with _$SQFlowCollationTestMixin {
  @override
  @ID()
  final String id;

  @Column(collate: Collate.noCase)
  final String nameNoCase;

  @Column(collate: Collate.binary)
  final String nameBinary;

  CollationTest({
    required this.id,
    required this.nameNoCase,
    required this.nameBinary,
  });

  factory CollationTest.fromJson(Map<String, dynamic> json) =>
      _$SQFlowCollationTestFromJson(json);
}
