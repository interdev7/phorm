import 'package:sqflow_core/sqflow_core.dart';

part 'migration_user.sql.g.dart';

@Schema(
  tableName: 'migration_users',
)
class MigrationUser extends Model with _$SQFlowMigrationUserMixin {
  @ID(type: TEXT(), autoIncrement: false)
  @override
  final String id;

  @Column(type: TEXT())
  final String name;

  @Column(type: TEXT())
  final String? email;

  @Column(type: INTEGER())
  final int? age;

  @Column(type: INTEGER(), defaultValue: true)
  final bool isActive;

  MigrationUser({
    required this.id,
    required this.name,
    this.email,
    this.age,
    this.isActive = true,
  });

  factory MigrationUser.fromJson(Map<String, dynamic> json) =>
      _$SQFlowMigrationUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SQFlowMigrationUserToJson();
}
