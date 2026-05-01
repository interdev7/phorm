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
  gender TEXT NOT NULL CONSTRAINT gender_check CHECK(gender IN ('M', 'F', 'Other')),
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  address TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_verified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE UNIQUE INDEX users_email_idx ON users(email);
CREATE INDEX users_first_name_last_name_idx ON users(first_name, last_name);
""";

class _$SQFlowUserTable extends Table<User> {
  _$SQFlowUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
  }) : super(type: User, paranoid: Table.detectSoftDelete(schema));
}

/// User table schema
final usersTable = _$SQFlowUserTable(
  schema: _$SQFlowUserSchema,
  name: 'users',
  fromJson: User.fromJson,
  relationships: const [
    HasMany(model: 'orders', foreignKey: 'user_id'),
    HasMany(model: 'posts', foreignKey: 'user_id'),
    HasOne(model: 'profiles', foreignKey: 'user_id')
  ],
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
);

mixin _$SQFlowUserMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  final List<Order> _$orders = [];
  List<Order> get orders => _$orders;
  final List<Post> _$posts = [];
  List<Post> get posts => _$posts;
  Profile? _$profile;
  Profile? get profile => _$profile;
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
    birthDate: json['birth_date'] as String?,
    age: json['age'] as int?,
    gender: json['gender'] as String,
    city: json['city'] as String,
    country: json['country'] as String,
    address: json['address'] as String?,
    isActive: json['is_active'] is bool
        ? json['is_active'] as bool
        : (json['is_active'] as int?) == 1,
    isVerified: json['is_verified'] is bool
        ? json['is_verified'] as bool
        : (json['is_verified'] as int?) == 1,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null
    ..deletedAt = json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null
    ..orders.addAll(json['orders'] != null
        ? (json['orders'] as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList()
        : [])
    ..posts.addAll(json['posts'] != null
        ? (json['posts'] as List)
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList()
        : [])
    .._$profile = json['profiles'] != null
        ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
        : null;
  return instance;
}

const _$SQFlowPostSchema = """
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE INDEX posts_user_id_idx ON posts(user_id);
""";

class _$SQFlowPostTable extends Table<Post> {
  _$SQFlowPostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
  }) : super(type: Post, paranoid: Table.detectSoftDelete(schema));
}

/// Post table schema
final postsTable = _$SQFlowPostTable(
  schema: _$SQFlowPostSchema,
  name: 'posts',
  fromJson: Post.fromJson,
  relationships: const [BelongsTo(model: 'users', foreignKey: 'user_id')],
  columns: const [
    'id',
    'title',
    'user_id',
    'created_at',
    'updated_at',
    'deleted_at'
  ],
);

mixin _$SQFlowPostMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  User? _$user;
  User? get user => _$user;
}

extension SQFlowPostSqlExt on Post {
  Map<String, dynamic> _$SQFlowPostToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'title': _$SQFlowToJsonValue(title),
      'user_id': _$SQFlowToJsonValue(userId),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
      'deleted_at': _$SQFlowToJsonValue(deletedAt),
    };
  }

  Post copyWith({
    int? id,
    String? title,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..deletedAt = deletedAt ?? this.deletedAt;
  }
}

Post _$SQFlowPostFromJson(Map<String, dynamic> json) {
  final instance = Post(
    id: json['id'] as int,
    title: json['title'] as String,
    userId: json['user_id'] as String,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null
    ..deletedAt = json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null
    .._$user = json['users'] != null
        ? User.fromJson(json['users'] as Map<String, dynamic>)
        : null;
  return instance;
}

const _$SQFlowProfileSchema = """
CREATE TABLE profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  bio TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE UNIQUE INDEX profiles_user_id_idx ON profiles(user_id);
""";

class _$SQFlowProfileTable extends Table<Profile> {
  _$SQFlowProfileTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
  }) : super(type: Profile, paranoid: Table.detectSoftDelete(schema));
}

/// Profile table schema
final profilesTable = _$SQFlowProfileTable(
  schema: _$SQFlowProfileSchema,
  name: 'profiles',
  fromJson: Profile.fromJson,
  relationships: const [BelongsTo(model: 'users', foreignKey: 'user_id')],
  columns: const ['id', 'bio', 'user_id', 'created_at', 'updated_at'],
);

mixin _$SQFlowProfileMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  User? _$user;
  User? get user => _$user;
}

extension SQFlowProfileSqlExt on Profile {
  Map<String, dynamic> _$SQFlowProfileToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'bio': _$SQFlowToJsonValue(bio),
      'user_id': _$SQFlowToJsonValue(userId),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
  }

  Profile copyWith({
    int? id,
    String? bio,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      bio: bio ?? this.bio,
      userId: userId ?? this.userId,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

Profile _$SQFlowProfileFromJson(Map<String, dynamic> json) {
  final instance = Profile(
    id: json['id'] as int,
    bio: json['bio'] as String,
    userId: json['user_id'] as String,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null
    .._$user = json['users'] != null
        ? User.fromJson(json['users'] as Map<String, dynamic>)
        : null;
  return instance;
}

const _$SQFlowOrderSchema = """
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  total INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE INDEX orders_user_id_idx ON orders(user_id);
""";

class _$SQFlowOrderTable extends Table<Order> {
  _$SQFlowOrderTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
  }) : super(type: Order, paranoid: Table.detectSoftDelete(schema));
}

/// Order table schema
final ordersTable = _$SQFlowOrderTable(
  schema: _$SQFlowOrderSchema,
  name: 'orders',
  fromJson: Order.fromJson,
  relationships: const [BelongsTo(model: 'users', foreignKey: 'user_id')],
  columns: const [
    'id',
    'total',
    'user_id',
    'created_at',
    'updated_at',
    'deleted_at'
  ],
);

mixin _$SQFlowOrderMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  User? _$user;
  User? get user => _$user;
}

extension SQFlowOrderSqlExt on Order {
  Map<String, dynamic> _$SQFlowOrderToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'total': _$SQFlowToJsonValue(total),
      'user_id': _$SQFlowToJsonValue(userId),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
      'deleted_at': _$SQFlowToJsonValue(deletedAt),
    };
  }

  Order copyWith({
    int? id,
    int? total,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Order(
      id: id ?? this.id,
      total: total ?? this.total,
      userId: userId ?? this.userId,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..deletedAt = deletedAt ?? this.deletedAt;
  }
}

Order _$SQFlowOrderFromJson(Map<String, dynamic> json) {
  final instance = Order(
    id: json['id'] as int,
    total: json['total'] as int,
    userId: json['user_id'] as String,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null
    ..deletedAt = json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null
    .._$user = json['users'] != null
        ? User.fromJson(json['users'] as Map<String, dynamic>)
        : null;
  return instance;
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
