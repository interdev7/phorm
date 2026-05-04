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
CREATE INDEX users_first_name_last_name_idx ON users(first_name, last_name);

CREATE TRIGGER update_users_timestamp
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    UPDATE users SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowUserTable extends Table<User> {
  _$SQFlowUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.timestamps = true,
  }) : super(type: User, paranoid: Table.detectSoftDelete(schema));
}

/// User table schema
final usersTable = _$SQFlowUserTable(
  schema: _$SQFlowUserSchema,
  name: 'users',
  fromJson: _$SQFlowUserFromJson,
  relationships: const [HasMany(model: 'posts', foreignKey: 'user_id')],
  columns: const [
    'id',
    'first_name',
    'last_name',
    'email',
    'phone',
    'birth_date',
    'age',
    'gender',
    'city',
    'country',
    'address',
    'is_active',
    'is_verified',
    'created_at',
    'updated_at',
    'deleted_at'
  ],
  timestamps: true,
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

class UserTable {
  static const SqflowColumn<String> id = SqflowColumn<String>('id');
  static const SqflowColumn<String> firstName =
      SqflowColumn<String>('first_name');
  static const SqflowColumn<String> lastName =
      SqflowColumn<String>('last_name');
  static const SqflowColumn<String> email = SqflowColumn<String>('email');
  static const SqflowColumn<String> phone = SqflowColumn<String>('phone');
  static const SqflowColumn<String> birthDate =
      SqflowColumn<String>('birth_date');
  static const SqflowColumn<int> age = SqflowColumn<int>('age');
  static const SqflowColumn<String> gender = SqflowColumn<String>('gender');
  static const SqflowColumn<String> city = SqflowColumn<String>('city');
  static const SqflowColumn<String> country = SqflowColumn<String>('country');
  static const SqflowColumn<String> address = SqflowColumn<String>('address');
  static const SqflowColumn<bool> isActive = SqflowColumn<bool>('is_active');
  static const SqflowColumn<bool> isVerified =
      SqflowColumn<bool>('is_verified');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');
  static const SqflowColumn<DateTime> deletedAt =
      SqflowColumn<DateTime>('deleted_at');
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
