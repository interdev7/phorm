import 'package:flutter_test/flutter_test.dart';
import 'package:phorm/phorm.dart';

void main() {
  group('SqlFunctionColumn', () {
    test('renders as functionName(innerColumn)', () {
      const inner = PhormColumn<String>('name');
      final fn = SqlFunctionColumn<int>('LENGTH', inner);
      expect(fn.name, 'LENGTH(name)');
      expect(fn.functionName, 'LENGTH');
      expect(fn.innerColumn, inner);
      expect(fn.toString(), 'LENGTH(name)');
    });

    test('nests with qualified columns', () {
      const inner = PhormColumn<String>('name', tableName: 'users');
      final fn = SqlFunctionColumn<int>('UPPER', inner);
      expect(fn.name, 'UPPER(users.name)');
    });
  });

  group('SqlFunctions.apply / sqlFunction extension', () {
    test('apply wraps a column in a function call', () {
      final col = SqlFunctions.apply<String, int>(
        'LENGTH',
        const PhormColumn<String>('name'),
      );
      expect(col, isA<SqlFunctionColumn<int>>());
      expect(col.name, 'LENGTH(name)');
    });

    test('extension applies a function fluently', () {
      final col = const PhormColumn<String>('name').sqlFunction<int>('LENGTH');
      expect(col.name, 'LENGTH(name)');
    });
  });
}
