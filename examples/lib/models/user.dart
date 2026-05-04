import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';
import 'post.dart';

part 'user.sql.g.dart';

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
class User extends Model with _$SQFlowUserMixin {
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
    this.posts = const [],
  });

  final List<Post> posts;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$SQFlowUserFromJson(json);
  @ID(type: TEXT(), autoIncrement: false, unique: true)
  @override
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
    check: CHECK(['M', 'F', 'Other']),
  )
  final String gender;

  @Column(type: TEXT())
  final String city;

  @Column(type: TEXT())
  final String country;

  @Column(type: TEXT())
  final String address;

  @Column(type: INTEGER(), defaultValue: true)
  final bool isActive;

  @Column(type: INTEGER(), defaultValue: false)
  final bool isVerified;

  @override
  Map<String, dynamic> toJson() => _$SQFlowUserToJson();
}
