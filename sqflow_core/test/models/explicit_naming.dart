import 'package:sqflow_core/sqflow_core.dart';

part 'explicit_naming.sql.g.dart';

@Schema(
  tableName: 'explicit_table',
  columnNaming: ColumnNamingStrategy.snakeCase,
)
class ExplicitNaming extends Model with _$SQFlowExplicitNamingMixin {
  @ID(type: TEXT(), columnName: 'custom_id')
  @override
  final String id;

  @Column(type: TEXT(), columnName: 'custom_name')
  final String name;

  @Column(type: INTEGER(), columnName: 'custom_age')
  final int age;

  @Column(type: INTEGER(), columnName: 'is_verified')
  bool isVerified;

  ExplicitNaming({
    required this.id,
    required this.name,
    required this.age,
    this.isVerified = false,
  });

  factory ExplicitNaming.fromJson(Map<String, dynamic> json) =>
      _$SQFlowExplicitNamingFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SQFlowExplicitNamingToJson();
}
