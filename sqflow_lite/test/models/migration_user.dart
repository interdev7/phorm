import 'package:sqflow/sqflow.dart';
import 'package:sqflow_lite/sqflow_lite.dart';

part 'migration_user.sql.g.dart';

late DB appDb;

@Schema(
  tableName: 'migration_users',
)
class MigrationUser extends Model with _$SQFlowMigrationUserMixin {
  @ID(autoIncrement: false, columnName: 'custom_id')
  final String id;

  @Column()
  final String name;

  @Column()
  final String? email;

  @Column()
  final int? age;

  @Column(defaultValue: true)
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
}
