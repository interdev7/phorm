import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'package:phorm_example/db.dart';

import 'post.dart';
import 'validators.dart';

part 'user.sql.g.dart';

class IsNumberValidator implements IJsonValidator {
  @override
  String? get constraint => 'is_number';

  const IsNumberValidator();

  @override
  bool isValid(dynamic value) {
    if (value is! String) return false;
    return RegExp(r'^\+?\d+$').hasMatch(value);
  }
}

@Schema(
  tableName: 'users',
  paranoid: true,
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['first_name', 'last_name']),
  ],
  relationships: [
    HasMany(
      model: 'posts',
      foreignKey: 'user_id',
      localKey: 'id',
    ),
  ],
)
class User extends Model with _$PhormUserMixin {
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.city,
    required this.country,
    required this.address,
    this.birthDate,
    this.age,
    this.isActive = true,
    this.isVerified = false,
    this.metadata,
    required this.password,
    this.posts = const [],
  });

  final List<Post> posts;

  factory User.fromJson(Map<String, dynamic> json) => _$PhormUserFromJson(json);
  @ID(autoIncrement: false, unique: true)
  final String id;

  @Column(
    validators: [
      LengthValidator(min: 2, max: 50, constraint: 'first_name_length'),
      NotEmptyValidator(),
    ],
  )
  final String firstName;

  @Column(
    validators: [
      LengthValidator(min: 2, max: 50, constraint: 'last_name_length'),
      NotEmptyValidator(),
    ],
  )
  final String lastName;

  @Column(
    unique: true,
    validators: [
      EmailValidator(constraint: 'email_format'),
      NotEmptyValidator(),
    ],
  )
  final String email;

  @Column(
    validators: [
      IsNumberValidator(),
      NotEmptyValidator(),
      LengthValidator(min: 6, max: 15, constraint: 'phone_length'),
    ],
  )
  final String phone;

  @Column(
    validators: [
      RegExpValidator(r'\d{4}-\d{2}-\d{2}', constraint: 'date_format'),
    ],
  )
  final String? birthDate;

  @Column()
  final int? age;

  @Column(
    validators: [
      ContainsValidator(['M', 'F', 'Other'], constraint: 'gender_check'),
    ],
  )
  final String gender;

  @Column()
  final String city;

  @Column()
  final String country;

  @Column()
  final String address;

  @Column(defaultValue: true)
  final bool isActive;

  @Column(defaultValue: false)
  final bool isVerified;

  @Column(converter: JsonMapConverter())
  final Map<String, dynamic>? metadata;

  @Column(converter: PasswordConverter())
  final String password;
}

class PasswordConverter extends ValueConverter<String, String> {
  const PasswordConverter();

  @override
  String fromSql(String sqlValue) {
    // Simple mock: remove prefix
    return sqlValue.startsWith('hash_') ? sqlValue.substring(5) : sqlValue;
  }

  @override
  String toSql(String value) {
    // Simple mock: add prefix
    return 'hash_$value';
  }
}

class JsonMapConverter extends ValueConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String sqlValue) {
    return jsonDecode(sqlValue) as Map<String, dynamic>;
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}
