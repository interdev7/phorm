// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm_generator/phorm_generator.dart';

// `phorm_generator` is a build-time code generator. You normally don't call it
// directly: add it to `dev_dependencies`, annotate your models with `@Schema`
// from `phorm_annotations`, and run `dart run build_runner build`.
//
// This example just shows that the generator entry points are available.
void main() {
  final generator = PhormSchemaGenerator();
  print('Schema generator ready: ${generator.runtimeType}');
}
