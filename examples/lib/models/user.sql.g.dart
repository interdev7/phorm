// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'user.dart';

const _$SQFlowUserSchema = """
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  birth_date TEXT,
  age INTEGER,
  gender TEXT NOT NULL CHECK(gender IN ('M', 'F', 'Other')),
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  address TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_verified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE UNIQUE INDEX users_email_idx ON users(email);
CREATE INDEX users_firstName_lastName_idx ON users(firstName, lastName);
""";

class _$SQFlowUserTable extends Table<User> {
  _$SQFlowUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: User, paranoid: Table.detectSoftDelete(schema));
}

/// User table schema
final usersTable = _$SQFlowUserTable(
  schema: _$SQFlowUserSchema,
  name: 'users',
  fromJson: User.fromJson,
  relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
);

mixin _$SQFlowUserMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
}

extension SQFlowUserSqlExt on User {
  Map<String, dynamic> _$SQFlowUserToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'first_name': _$SQFlowToJsonValue(firstName),
      'last_name': _$SQFlowToJsonValue(lastName),
      'email': _$SQFlowToJsonValue(email),
      'phone': _$SQFlowToJsonValue(phone),
      'birth_date': _$SQFlowToJsonValue(birthDate),
      'age': _$SQFlowToJsonValue(age),
      'gender': _$SQFlowToJsonValue(gender),
      'city': _$SQFlowToJsonValue(city),
      'country': _$SQFlowToJsonValue(country),
      'address': _$SQFlowToJsonValue(address),
      'is_active': _$SQFlowToJsonValue(isActive),
      'is_verified': _$SQFlowToJsonValue(isVerified),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
      'deleted_at': _$SQFlowToJsonValue(deletedAt),
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? gender,
    String? city,
    String? country,
    String? address,
    String? birthDate,
    int? age,
    bool? isActive,
    bool? isVerified,
    List<Post>? posts,
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
      gender: gender ?? this.gender,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      posts: posts ?? this.posts,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..deletedAt = deletedAt ?? this.deletedAt;
  }
}

User _$SQFlowUserFromJson(Map<String, dynamic> json) {
  final instance = User(
    id: json['id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    gender: json['gender'] as String,
    city: json['city'] as String,
    country: json['country'] as String,
    address: json['address'] as String,
    birthDate: json['birth_date'] as String?,
    age: json['age'] as int?,
    isActive: json['is_active'] is bool
        ? json['is_active'] as bool
        : (json['is_active'] as int?) == 1,
    isVerified: json['is_verified'] is bool
        ? json['is_verified'] as bool
        : (json['is_verified'] as int?) == 1,
    posts: json['posts'] != null
        ? (json['posts'] as List)
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList()
        : [],
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null
    ..deletedAt = json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null;
  return instance;
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
