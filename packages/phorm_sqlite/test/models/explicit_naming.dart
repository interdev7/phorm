import 'package:phorm_sqlite/phorm_sqlite.dart';

part 'explicit_naming.sql.g.dart';

late DB appDb;

@Schema(
  tableName: 'explicit_table',
  columnNaming: ColumnNamingStrategy.snakeCase,
)
class ExplicitNaming extends Model with _$PhormExplicitNamingMixin {
  @ID(columnName: 'custom_id')
  final String id;

  @Column(columnName: 'custom_name')
  final String name;

  @Column(columnName: 'custom_age')
  final int age;

  @Column(columnName: 'is_verified')
  bool isVerified;

  ExplicitNaming({
    required this.id,
    required this.name,
    required this.age,
    this.isVerified = false,
  });

  factory ExplicitNaming.fromJson(Map<String, dynamic> json) =>
      _$PhormExplicitNamingFromJson(json);
}
