class User with UserMixin {}

mixin UserMixin {
  final List<String> _posts = [];
  List<String> get posts => _posts;
}

void test() {
  final u = User();
  u._posts.add('Hello');
  print(u.posts);
}

void main() {
  test();
}
