import 'package:phorm_sqlite/phorm_sqlite.dart';

part 'custom_functions.fn.g.dart';

@SqlFunc(name: 'DOUBLE')
int? doubleValue(int? val) {
  if (val == null) return null;
  return val * 2;
}

@SqlFunc(name: 'TO_SLUG')
String? toSlug(String? val) {
  if (val == null) return null;
  return val.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
}

@SqlFunc(name: 'IS_ADULT')
bool? isAdult(int? age) {
  if (age == null) return null;
  return age >= 18;
}
