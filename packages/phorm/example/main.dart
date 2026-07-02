// Examples print to the console for illustration only.
// ignore_for_file: avoid_print

import 'package:phorm/phorm.dart';

void main() {
  // 1. Build a type-safe WHERE clause without writing raw SQL by hand.
  //    Conditions are chained fluently and compiled for the active dialect.
  final where = WhereBuilder()
      .eq('is_active', true)
      .gte('age', 18)
      .like('email', '%@example.com')
      .inList('role', ['admin', 'editor']);

  print('WHERE ${where.build()}');
  print('args:  ${where.args}\n');

  // 2. Group conditions with OR and nest them inside the same builder.
  final grouped = WhereBuilder()
      .eq('deleted_at', null)
      .orGroup((g) => g.eq('role', 'admin').eq('role', 'owner'));

  print('grouped: ${grouped.build()}\n');

  // 3. Compose ordering with the SortBuilder.
  final sort = SortBuilder().desc('created_at').asc('name');
  print('ORDER BY ${sort.build()}\n');

  // 4. `addIf` conditionally appends a clause, so you can build filters from
  //    optional user input without scattering `if` statements everywhere.
  const isAdminView = true;
  final conditional = WhereBuilder()
      .eq('is_active', true)
      .addIf(isAdminView, (b) => b.eq('role', 'admin'));

  print('conditional: ${conditional.build()}\n');

  // 5. Type-safe columns carry their Dart type, so comparison helpers only
  //    accept matching values — mistakes are caught at compile time.
  const age = PhormColumn<int>('age');
  const name = PhormColumn<String>('name');
  print('typed columns: ${name.name} (String), ${age.name} (int)');
}
