import 'package:phorm_postgres/phorm_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresDialect', () {
    final dialect = PostgresDialect();

    test('compilePlaceholder uses positional dollar-number style', () {
      expect(dialect.compilePlaceholder(1), r'$1');
      expect(dialect.compilePlaceholder(2), r'$2');
      expect(dialect.compilePlaceholder(42), r'$42');
    });

    test('escapeIdentifier quotes a simple identifier with double quotes', () {
      expect(dialect.escapeIdentifier('users'), '"users"');
    });

    test('escapeIdentifier quotes each part of a qualified identifier', () {
      expect(dialect.escapeIdentifier('users.id'), '"users"."id"');
      expect(
        dialect.escapeIdentifier('schema.users.id'),
        '"schema"."users"."id"',
      );
    });

    test('compileJsonObject throws UnimplementedError (not yet implemented)',
        () {
      expect(
        () => dialect.compileJsonObject({'name': 'users.name'}),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('compileJsonArray throws UnimplementedError (not yet implemented)',
        () {
      expect(
        () => dialect.compileJsonArray('jsonObject', 'FROM users'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('implements SqlDialect', () {
      expect(dialect, isA<SqlDialect>());
    });
  });
}
