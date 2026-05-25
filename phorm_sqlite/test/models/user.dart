import 'package:phorm_sqlite/phorm_sqlite.dart';

part 'user.sql.g.dart';

late DB appDb;

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
    HasMany(model: Order, foreignKey: 'user_id'),
    HasMany(model: Post, foreignKey: 'user_id'),
    HasOne(model: Profile, foreignKey: 'user_id'),
  ],
)
class User extends Model with _$SQFlowUserMixin {
  @ID(autoIncrement: false, unique: true)
  final String id;

  @Column(
    validators: [
      LengthValidator(min: 3, max: 30, constraint: 'first_name_length_check'),
      NotEmptyValidator(),
    ],
  )
  final String firstName;

  @Column(
    validators: [
      LengthValidator(min: 3, max: 30, constraint: 'last_name_length_check'),
      NotEmptyValidator(),
    ],
  )
  final String lastName;

  @Column(
    unique: true,
    validators: [
      EmailValidator(constraint: 'email_format_check'),
      NotEmptyValidator(),
    ],
  )
  final String email;

  @Column(
    validators: [
      IsNumberValidator(),
      NotEmptyValidator(),
      LengthValidator(min: 6, max: 15, constraint: 'phone_length_check'),
    ],
  )
  final String phone;

  @Column(
    validators: [
      RegExpValidator(
        r'\d{4}-\d{2}-\d{2}',
        constraint: 'date_format', // yyyy-MM-dd
      ),
    ],
  )
  final String? birthDate;

  @Column()
  final int? age;

  @Column(
    validators: [
      ContainsValidator(['M', 'F', 'Other'], constraint: 'gender_check'),
      NotEmptyValidator(),
    ],
  )
  final String gender;

  @Column(validators: [NotEmptyValidator()])
  final String city;

  @Column(validators: [NotEmptyValidator()])
  final String country;

  @Column()
  final String? address;

  @Column(defaultValue: true)
  final bool isActive;

  @Column(defaultValue: false)
  final bool isVerified;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.city,
    required this.country,
    this.birthDate,
    this.age,
    this.address,
    this.isActive = true,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) =>
      _$SQFlowUserFromJson(json);
}

@Schema(
  tableName: 'posts',
  paranoid: true,
  indexes: [
    Index(columns: ['user_id']),
  ],
  relationships: [
    BelongsTo(model: User, foreignKey: 'user_id'),
  ],
)
class Post extends Model with _$SQFlowPostMixin {
  @ID(autoIncrement: true)
  final int id;

  @Column()
  final String title;

  @Column(columnName: 'user_id')
  final String userId;

  Post({
    required this.id,
    required this.title,
    required this.userId,
  });

  factory Post.fromJson(Map<String, dynamic> json) =>
      _$SQFlowPostFromJson(json);
}

@Schema(
  tableName: 'profiles',
  indexes: [
    Index(columns: ['user_id'], unique: true),
  ],
  relationships: [
    BelongsTo(model: User, foreignKey: 'user_id'),
  ],
)
class Profile extends Model with _$SQFlowProfileMixin {
  @ID(autoIncrement: true)
  final int id;

  @Column()
  final String bio;

  @Column(columnName: 'user_id')
  final String userId;

  Profile({
    required this.id,
    required this.bio,
    required this.userId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$SQFlowProfileFromJson(json);
}

@Schema(
  tableName: 'orders',
  paranoid: true,
  indexes: [
    Index(columns: ['user_id']),
  ],
  relationships: [
    BelongsTo(model: User, foreignKey: 'user_id'),
  ],
)
class Order extends Model with _$SQFlowOrderMixin {
  @ID(autoIncrement: true)
  final int id;

  @Column()
  final int total;

  @Column(columnName: 'user_id')
  final String userId;

  Order({
    required this.id,
    required this.total,
    required this.userId,
  });

  factory Order.fromJson(Map<String, dynamic> json) =>
      _$SQFlowOrderFromJson(json);
}
