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

  @Column(type: TEXT())
  @override
  final DateTime createdAt;

  @Column(type: TEXT())
  @override
  final DateTime? updatedAt;

  @Column(type: TEXT())
  @override
  final DateTime? deletedAt;

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
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  String get fullName => '$firstName $lastName';

  @override
  Map<String, dynamic> toJson() => _$SQFlowUserToJson();

  factory User.fromJson(Map<String, dynamic> json) =>
      _$SQFlowUserFromJson(json);

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? birthDate,
    int? age,
    String? gender,
    String? city,
    String? country,
    String? address,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
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

  @Column(type: TEXT())
  @override
  final DateTime createdAt;

  @Column(type: TEXT())
  @override
  final DateTime? updatedAt;

  @Column(type: TEXT())
  @override
  final DateTime? deletedAt;

  Order({
    required this.id,
    required this.total,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  Map<String, dynamic> toJson() => _$SQFlowOrderToJson();

  factory Order.fromJson(Map<String, dynamic> json) =>
      _$SQFlowOrderFromJson(json);
}
