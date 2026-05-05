import 'common.dart';

void main() {
  group('Dart-Side Validation Tests', () {
    test('toJson() should throw SqflowCheckException for invalid gender', () {
      final user = User(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '123456',
        gender: 'X', // Invalid gender
        city: 'New York',
        country: 'USA',
        isActive: true,
        isVerified: false,
      );

      expect(
        () => user.toJson(),
        throwsA(isA<SqflowCheckException>()
            .having((e) => e.table, 'table', 'users')
            .having((e) => e.column, 'column', 'gender')
            .having((e) => e.constraint, 'constraint', 'gender_check')),
      );
    });

    test('toJson() should throw SqflowCheckException for short firstName', () {
      final user = User(
        id: '1',
        firstName: 'Jo', // Too short (min 3)
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '123456',
        gender: 'M',
        city: 'New York',
        country: 'USA',
        isActive: true,
        isVerified: false,
      );

      expect(
        () => user.toJson(),
        throwsA(isA<SqflowCheckException>()
            .having((e) => e.column, 'column', 'first_name')
            .having((e) => e.constraint, 'constraint', 'name_length_check')),
      );
    });

    test('toJson() should succeed for valid data', () {
      final user = User(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '123456',
        gender: 'M',
        city: 'New York',
        country: 'USA',
        isActive: true,
        isVerified: false,
      );

      expect(() => user.toJson(), returnsNormally);
      final json = user.toJson();
      expect(json['gender'], equals('M'));
      expect(json['first_name'], equals('John'));
    });
  });
}
