import 'package:sqflow_core/sqflow_core.dart';

part 'custom_functions.fn.g.dart';

@SqlFunc(name: 'TO_SLUG')
String? toSlug(String? val) {
  if (val == null) return null;
  return val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

@SqlFunc(name: 'DOUBLE')
int? doubleValue(int? val) {
  if (val == null) return null;
  return val * 2;
}
