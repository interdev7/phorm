// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm/phorm.dart';

void main() {
  // Build a type-safe WHERE clause without writing raw SQL by hand.
  final where = WhereBuilder()
      .eq('is_active', true)
      .eq('role', 'admin');

  print('WHERE ${where.build()}');
  print('args:  ${where.args}');
}
