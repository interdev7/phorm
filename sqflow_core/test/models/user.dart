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
  ],
)
class User extends Model with _$SQFlowUserMixin {
  @ID(type: TEXT(), autoIncrement: false, unique: true)
  final String id;

  @Column(type: TEXT())
  final String firstName;

  @Column(type: TEXT())
  final String lastName;

  @Column(type: TEXT(), unique: true)
  final String email;

  @Column(type: TEXT())
  final String phone;

  @Column(type: TEXT())
  final String? birthDate;

  @Column(type: INTEGER())
  final int? age;

  @Column(
    type: TEXT(),
    check: CHECK(['M', 'F', 'Other'], constraint: 'gender_check'),
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
  tableName: 'orders',
  paranoid: true,
  relationships: [
    BelongsTo(model: User, foreignKey: 'user_id'),
  ],
)
class Order extends Model with _$SQFlowOrderMixin {
  @ID(type: INTEGER(), autoIncrement: true)
  final int id;

  @Column(type: INTEGER())
  final int total;



  Order({
    required this.id,
    required this.total,
  });

  @override
  Map<String, dynamic> toJson() => _$SQFlowOrderToJson();

  factory Order.fromJson(Map<String, dynamic> json) =>
      _$SQFlowOrderFromJson(json);
}
