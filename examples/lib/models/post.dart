import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';
import 'user.dart';

part 'post.sql.g.dart';

@Schema(tableName: 'posts')
class Post extends Model with _$SQFlowPostMixin {
  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$SQFlowPostFromJson(json);

  @ID( autoIncrement: true)
  @override
  final int id;

  @Column()
  final String title;

  @Column()
  final String content;

  @Column()
  final String userId;

  @Join(model: 'users', foreignKey: 'user_id')
  final User? user;

  @override
  Map<String, dynamic> toJson() => _$SQFlowPostToJson();
}
