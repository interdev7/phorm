import '../models/user.dart';
import '../test_utils.dart';

void main() {
  group('Dart-Side Validation Tests', () {
    test(
        'toJson() should throw PhormJSONValidatorException for invalid gender',
        () {
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
        throwsA(isA<PhormJSONValidatorException>()
            .having((e) => e.table, 'table', 'users')
            .having((e) => e.column, 'column', 'gender')
            .having((e) => e.constraint, 'constraint', 'gender_check')),
      );
    });

    test(
        'toJson() should throw PhormJSONValidatorException for short firstName',
        () {
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
        throwsA(isA<PhormJSONValidatorException>()
            .having((e) => e.column, 'column', 'first_name')
            .having(
                (e) => e.constraint, 'constraint', 'first_name_length_check')),
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

  test("should throw PhormJSONValidatorException for invalid email", () {
    final user = User(
      id: '1',
      firstName: 'John',
      lastName: 'Doe',
      email: 'invalid-email', // Invalid email
      phone: '123456',
      gender: 'M',
      city: 'New York',
      country: 'USA',
      isActive: true,
      isVerified: false,
    );

    expect(
      () => user.toJson(),
      throwsA(isA<PhormJSONValidatorException>()
          .having((e) => e.table, 'table', 'users')
          .having((e) => e.column, 'column', 'email')
          .having((e) => e.constraint, 'constraint', 'email_format_check')),
    );
  });

  // test("should throw PhormCheckException for null first_name", () {
  //   final user = User(
  //     id: '1',
  //     firstName: unsafeCast<String>(null), // null value on required field
  //     lastName: 'Doe',
  //     email: 'john@example.com',
  //     phone: '123456',
  //     gender: 'M',
  //     city: 'New York',
  //     country: 'USA',
  //     isActive: true,
  //     isVerified: false,
  //   );

  //   expect(
  //     () => user.toJson(),
  //     throwsA(isA<PhormCheckException>()
  //         .having((e) => e.table, 'table', 'users')
  //         .having((e) => e.column, 'column', 'first_name')
  //         .having((e) => e.constraint, 'constraint', 'null_field')),
  //   );
  // });
}
