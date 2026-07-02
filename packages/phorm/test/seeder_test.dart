import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

class _FakeDb implements PhormDatabase {
  @override
  SqlDialect get dialect => const NoEscapeDialect();
  @override
  List<Table> get tables => const [];
  @override
  PhormLogger? get logger => null;
  @override
  int get isolateThreshold => 1000;
  @override
  Stream<String> get changeStream => const Stream.empty();
  @override
  Future<T> logAction<T>(
    String label,
    List<Object?>? arguments,
    Future<T> Function() action,
  ) =>
      action();
  @override
  Future<DatabaseExecutor> get executor => throw UnimplementedError();
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) =>
      throw UnimplementedError();
  @override
  Future<void> close() async {}
}

class _MySeeder extends Seeder {
  bool ran = false;
  @override
  Future<void> run(PhormDatabase db) async {
    ran = true;
  }
}

void main() {
  test('Seeder.run can be implemented and invoked', () async {
    final seeder = _MySeeder();
    await seeder.run(_FakeDb());
    expect(seeder.ran, isTrue);
  });
}
