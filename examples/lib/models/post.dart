import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';
import 'user.dart';

part 'post.sql.g.dart';

@Schema(tableName: 'posts')
class Post extends Model {
  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      userId: json['user_id'] as String,
      user: json['users'] != null ? User.fromJson(json['users'] as Map<String, dynamic>) : null,
    );
  }

  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String title;

  @Column(type: TEXT())
  final String content;

  @Column(type: TEXT())
  final String userId;

  @Join(model: 'users', foreignKey: 'user_id')
  final User? user;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'user_id': userId,
    };
  }
}
