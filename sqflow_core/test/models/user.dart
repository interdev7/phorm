import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

part 'user.sql.g.dart';

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
  @ID(type: TEXT(), autoIncrement: false, unique: true)
  @override
  final String id;

  @Column(
    type: TEXT(),
    check: CheckLength(min: 3, max: 30, constraint: 'name_length_check'),
  )
  final String firstName;

  @Column(
    type: TEXT(),
    check: CheckLength(min: 3, max: 30, constraint: 'last_name_length_check'),
  )
  final String lastName;

  @Column(
    type: TEXT(),
    unique: true,
    check: CheckEmail(
      constraint: 'email_format_check',
    ),
  )
  final String email;

  @Column(type: TEXT())
  final String phone;

  @Column(type: TEXT())
  final String? birthDate;

  @Column(type: INTEGER())
  final int? age;

  @Column(
    type: TEXT(),
    check: CheckInList(['M', 'F', 'Other'], constraint: 'gender_check'),
  )
  final String gender;

  @Column(type: TEXT())
  final String city;

  @Column(type: TEXT())
  final String country;

  @Column(type: TEXT())
  final String? address;

  @Column(type: INTEGER(), defaultValue: true)
  final bool isActive;

  @Column(type: INTEGER(), defaultValue: false)
  final bool isVerified;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.birthDate,
    this.age,
    required this.gender,
    required this.city,
    required this.country,
    this.address,
    this.isActive = true,
    this.isVerified = false,
  });

  String get fullName => '$firstName $lastName';

  @override
  Map<String, dynamic> toJson() => _$SQFlowUserToJson();

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
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String title;

  @Column(type: TEXT(), columnName: 'user_id')
  final String userId;

  Post({
    required this.id,
    required this.title,
    required this.userId,
  });

  @override
  Map<String, dynamic> toJson() => _$SQFlowPostToJson();

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
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String bio;

  @Column(type: TEXT(), columnName: 'user_id')
  final String userId;

  Profile({
    required this.id,
    required this.bio,
    required this.userId,
  });

  @override
  Map<String, dynamic> toJson() => _$SQFlowProfileToJson();

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
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: INTEGER())
  final int total;

  @Column(type: TEXT(), columnName: 'user_id')
  final String userId;

  Order({
    required this.id,
    required this.total,
    required this.userId,
  });

  @override
  Map<String, dynamic> toJson() => _$SQFlowOrderToJson();

  factory Order.fromJson(Map<String, dynamic> json) =>
      _$SQFlowOrderFromJson(json);
}
