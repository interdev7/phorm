import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_example/db.dart';
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

  factory Post.fromJson(Map<String, dynamic> json) =>
      _$SQFlowPostFromJson(json);

  @ID()
  @override
  final String id;

  @Column()
  final String title;

  @Column()
  final String content;

  @Column()
  final String userId;

  @Join(model: 'users', foreignKey: 'user_id')
  final User? user;

  /// Beautiful API Showcase
  static Future<void> showcase() async {
    // 1. Simple where with plural object
    final myPosts = await Posts.where(Posts.title.eq('Hello')).get();

    // 2. Chained query with complex conditions
    final flutterPosts = await Posts.where(Posts.content.like('%Flutter%'))
        .where(Posts.userId.isNotNull())
        .orderBy(Posts.createdAt, descending: true)
        .limit(5)
        .get();

    // 3. Get first result
    final firstPost = await Posts.where(Posts.id.eq('1')).first();

    print('Found ${myPosts.length} posts');
    print('Flutter posts: ${flutterPosts.length}');
    print('First post: $firstPost');
  }
}
