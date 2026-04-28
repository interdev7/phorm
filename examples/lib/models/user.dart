import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';
import 'post.dart';

part 'user.sql.g.dart';

@Schema(
  tableName: 'users',
  paranoid: true,
  indexes: [
    Index(columns: ['email'], unique: true),
    Index(columns: ['firstName', 'lastName']),
  ],
  hasMany: [
    HasMany(
      model: 'posts',
      foreignKey: 'user_id',
      localKey: 'id',
    ),
  ],
)
class User extends Model {
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
    required this.createdAt,
    this.birthDate,
    this.age,
    this.isActive = true,
    this.isVerified = false,
    this.updatedAt,
    this.deletedAt,
    this.posts = const [],
  });

  final List<Post> posts;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      birthDate: json['birthDate'] as String?,
      age: json['age'] != null ? (json['age'] as num).toInt() : null,
      gender: json['gender'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      address: json['address'] as String,
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      isVerified: json['isVerified'] == 1 || json['isVerified'] == true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      posts: json['posts'] != null
          ? (json['posts'] as List)
              .map((p) => Post.fromJson(p as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
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

  @Column(type: TEXT())
  @override
  final DateTime createdAt;

  @Column(type: TEXT())
  @override
  final DateTime? updatedAt;

  @Column(type: TEXT())
  @override
  final DateTime? deletedAt;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'birthDate': birthDate,
      'age': age,
      'gender': gender,
      'city': city,
      'country': country,
      'address': address,
      'isActive': isActive ? 1 : 0, // SQLite BOOLEAN as INTEGER
      'isVerified': isVerified ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
