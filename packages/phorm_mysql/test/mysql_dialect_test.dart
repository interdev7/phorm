import 'package:phorm_mysql/phorm_mysql.dart';
import 'package:test/test.dart';

void main() {
  group('MysqlDialect', () {
    final dialect = MysqlDialect();

    test('compilePlaceholder always returns ?', () {
      expect(dialect.compilePlaceholder(0), '?');
      expect(dialect.compilePlaceholder(1), '?');
      expect(dialect.compilePlaceholder(42), '?');
    });

    test('escapeIdentifier quotes a simple identifier with backticks', () {
      expect(dialect.escapeIdentifier('users'), '`users`');
    });

    test('escapeIdentifier quotes each part of a qualified identifier', () {
      expect(dialect.escapeIdentifier('users.id'), '`users`.`id`');
      expect(
        dialect.escapeIdentifier('db.users.id'),
        '`db`.`users`.`id`',
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
