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
  @ID( autoIncrement: false, unique: true)
  @override
  final String id;

  @Column()
  final String firstName;

  @Column()
  final String lastName;

  @Column( unique: true)
  final String email;

  @Column()
  final String phone;

  @Column()
  final String? birthDate;

  @Column()
  final int? age;

  @Column(
    
    check: ContainsValidator(['M', 'F', 'Other']),
  )
  final String gender;

  @Column()
  final String city;

  @Column()
  final String country;

  @Column()
  final String address;

  @Column( defaultValue: true)
  final bool isActive;

  @Column( defaultValue: false)
  final bool isVerified;

  @override
  Map<String, dynamic> toJson() => _$SQFlowUserToJson();
}
