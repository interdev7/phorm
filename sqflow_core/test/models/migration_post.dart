import 'package:sqflow_core/sqflow_core.dart';

part 'migration_post.sql.g.dart';

@Schema(
  tableName: 'migration_posts',
)
class MigrationPost extends Model with _$SQFlowMigrationPostMixin {
  @ID(type: TEXT(), autoIncrement: false)
  @override
  final String id;

  @Column(type: TEXT())
  final String title;

  @Column(type: TEXT())
  final String content;

  @Column(type: TEXT())
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
