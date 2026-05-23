import 'package:sqflow/sqflow.dart';
import 'package:sqflow_lite/sqflow_lite.dart';

part 'migration_post.sql.g.dart';

late DB appDb;

@Schema(
  tableName: 'migration_posts',
)
class MigrationPost extends Model with _$SQFlowMigrationPostMixin {
  @ID(autoIncrement: false)
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
}
