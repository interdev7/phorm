// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm_annotations/phorm_annotations.dart';

void main() {
  // Describe a table declaratively with PHORM annotations.
  // In a real project you put these annotations on your model classes and let
  // `phorm_generator` produce the schema, mappers and migrations for you.
  const userSchema = Schema(tableName: 'users');

  print('Configured table: ${userSchema.tableName}');
  print('Target dialect:   ${userSchema.dialect}');
  print('Timestamps:       ${userSchema.timestamps}');
}
