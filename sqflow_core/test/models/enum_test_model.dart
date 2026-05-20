import 'package:sqflow_core/sqflow_core.dart';

part 'enum_test_model.sql.g.dart';

late DB appDb;

enum PostStatus {
  draft,
  published,
  archived,
}

@Schema(
  tableName: 'enum_posts',
)
class EnumPost extends Model with _$SQFlowEnumPostMixin {
  @ID(autoIncrement: true)
  final int id;

  @Column()
  final String title;

  @Column()
  final PostStatus status;

  @Column()
  final PostStatus? optionalStatus;

  EnumPost({
    required this.id,
    required this.title,
    required this.status,
    this.optionalStatus,
  });

  factory EnumPost.fromJson(Map<String, dynamic> json) =>
      _$SQFlowEnumPostFromJson(json);
}
