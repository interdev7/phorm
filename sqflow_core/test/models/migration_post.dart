import 'package:sqflow_core/sqflow_core.dart';

part 'migration_post.sql.g.dart';

@Schema(
  tableName: 'migration_posts',
)
class MigrationPost extends Model with _$SQFlowMigrationPostMixin {
  @ID( autoIncrement: false)
  @override
  final String id;

  @Column()
  final String title;

  @Column()
  final String content;

  @Column()
  final String userId;

  MigrationPost({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
  });

  factory MigrationPost.fromJson(Map<String, dynamic> json) =>
      _$SQFlowMigrationPostFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SQFlowMigrationPostToJson();
}
