mixin M {
  @override
  String toString() => "From Mixin";
}

class C with M {}

void main() {
  print(C());
}
