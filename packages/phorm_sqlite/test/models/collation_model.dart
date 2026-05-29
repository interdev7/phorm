import 'package:phorm_sqlite/phorm_sqlite.dart';

part 'collation_model.sql.g.dart';

late DB appDb;

@Schema(tableName: 'collation_tests')
class CollationTest extends Model with _$PhormCollationTestMixin {
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
      _$PhormCollationTestFromJson(json);
}
