// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'user.dart';

const _$SQFlowUserSchema = """
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  first_name TEXT NOT NULL CONSTRAINT first_name_length_check CHECK(LENGTH(first_name) BETWEEN 3 AND 30),
  last_name TEXT NOT NULL CONSTRAINT last_name_length_check CHECK(LENGTH(last_name) BETWEEN 3 AND 30),
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL CONSTRAINT phone_length_check CHECK(LENGTH(phone) BETWEEN 6 AND 15),
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
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: User, paranoid: Table.detectSoftDelete(schema));
}

/// User table schema
final usersTable = _$SQFlowUserTable(
  schema: _$SQFlowUserSchema,
  name: 'users',
  fromJson: _$SQFlowUserFromJson,
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
  primaryKey: 'id',
  timestamps: true,
);

mixin _$SQFlowUserMixin {
  Map<String, dynamic> toJson() => _$SQFlowUserToJson(this as User);

  @override
  String toString() => _$SQFlowUserToString(this as User);
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

Map<String, dynamic> _$SQFlowUserToJson(User instance) {
  final userJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'first_name': _$SQFlowToJsonValue(instance.firstName),
    'last_name': _$SQFlowToJsonValue(instance.lastName),
    'email': _$SQFlowToJsonValue(instance.email),
    'phone': _$SQFlowToJsonValue(instance.phone),
    'birth_date': _$SQFlowToJsonValue(instance.birthDate),
    'age': _$SQFlowToJsonValue(instance.age),
    'gender': _$SQFlowToJsonValue(instance.gender),
    'city': _$SQFlowToJsonValue(instance.city),
    'country': _$SQFlowToJsonValue(instance.country),
    'address': _$SQFlowToJsonValue(instance.address),
    'is_active': _$SQFlowToJsonValue(instance.isActive),
    'is_verified': _$SQFlowToJsonValue(instance.isVerified),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
    'deleted_at': _$SQFlowToJsonValue(instance.deletedAt),
  };
  _$validateUser(userJson, tableName: 'users');

  return userJson;
}

String _$SQFlowUserToString(User instance) {
  return """
User(
  id: ${instance.id},
  firstName: ${instance.firstName},
  lastName: ${instance.lastName},
  email: ${instance.email},
  phone: ${instance.phone},
  birthDate: ${instance.birthDate},
  age: ${instance.age},
  gender: ${instance.gender},
  city: ${instance.city},
  country: ${instance.country},
  address: ${instance.address},
  isActive: ${instance.isActive},
  isVerified: ${instance.isVerified},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
  deletedAt: ${instance.deletedAt},
  orders: ${instance.orders},
  posts: ${instance.posts},
  profile: ${instance.profile},
)""";
}

extension SQFlowUserExt on User {
  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? gender,
    String? city,
    String? country,
    String? birthDate,
    int? age,
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
      gender: gender ?? this.gender,
      city: city ?? this.city,
      country: country ?? this.country,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..deletedAt = deletedAt ?? this.deletedAt;
  }
}

void _$validateUser(Map<String, dynamic> json, {required String tableName}) {
  if (!const LengthValidator(
          min: 3, max: 30, constraint: "first_name_length_check")
      .isValid(json['first_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'first_name',
      message: 'Value "${json['first_name']}" failed validation',
      constraint: 'first_name_length_check',
    );
  }
  if (!const NotEmptyValidator().isValid(json['first_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'first_name',
      message: 'Value "${json['first_name']}" failed validation',
    );
  }
  if (!const LengthValidator(
          min: 3, max: 30, constraint: "last_name_length_check")
      .isValid(json['last_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'last_name',
      message: 'Value "${json['last_name']}" failed validation',
      constraint: 'last_name_length_check',
    );
  }
  if (!const NotEmptyValidator().isValid(json['last_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'last_name',
      message: 'Value "${json['last_name']}" failed validation',
    );
  }
  if (!const EmailValidator(constraint: "email_format_check")
      .isValid(json['email'])) {
    throw SqflowJSONValidatorException(
      table: tableName,
      column: 'email',
      message: 'Value "${json['email']}" failed validation',
      constraint: 'email_format_check',
    );
  }
  if (!const NotEmptyValidator().isValid(json['email'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'email',
      message: 'Value "${json['email']}" failed validation',
    );
  }
  if (!const IsNumberValidator().isValid(json['phone'])) {
    throw SqflowJSONValidatorException(
      table: tableName,
      column: 'phone',
      message: 'Value "${json['phone']}" failed validation',
    );
  }
  if (!const NotEmptyValidator().isValid(json['phone'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'phone',
      message: 'Value "${json['phone']}" failed validation',
    );
  }
  if (!const LengthValidator(min: 6, max: 15, constraint: "phone_length_check")
      .isValid(json['phone'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'phone',
      message: 'Value "${json['phone']}" failed validation',
      constraint: 'phone_length_check',
    );
  }
  if (!const RegExpValidator("\\d{4}-\\d{2}-\\d{2}", constraint: "date_format")
      .isValid(json['birth_date'])) {
    throw SqflowJSONValidatorException(
      table: tableName,
      column: 'birth_date',
      message: 'Value "${json['birth_date']}" failed validation',
      constraint: 'date_format',
    );
  }
  if (!const ContainsValidator(["M", "F", "Other"], constraint: "gender_check")
      .isValid(json['gender'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'gender',
      message: 'Value "${json['gender']}" failed validation',
      constraint: 'gender_check',
    );
  }
  if (!const NotEmptyValidator().isValid(json['gender'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'gender',
      message: 'Value "${json['gender']}" failed validation',
    );
  }
  if (!const NotEmptyValidator().isValid(json['city'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'city',
      message: 'Value "${json['city']}" failed validation',
    );
  }
  if (!const NotEmptyValidator().isValid(json['country'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'country',
      message: 'Value "${json['country']}" failed validation',
    );
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
    birthDate: json['birth_date'] as String?,
    age: json['age'] as int?,
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

/// Pluralized service for User
class Users {
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

  static SqflowCore<User> get _service =>
      SqflowCore<User>(dbManager: appDb, table: usersTable);

  static SqflowQuery<User> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<User> get query => _service.query;

  static Future<int> insert(User item, {DatabaseExecutor? executor}) =>
      _service.insertAsync(item, executor: executor);
  static Future<int> update(User item, {DatabaseExecutor? executor}) =>
      _service.updateAsync(item, executor: executor);
  static Future<void> upsert(User item, {DatabaseExecutor? executor}) =>
      _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<User> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<User> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<User> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatchAsync(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatchAsync(ids, force: force, executor: executor);
  static Future<int> restoreBatch(List<Object> ids,
          {DatabaseExecutor? executor}) =>
      _service.restoreBatchAsync(ids, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.existsAsync(id, withDeleted: withDeleted, executor: executor);

  static Future<User?> read(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAsync(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<User>> readAll(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAll(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<ResultWithCount<User>> readAllWithCount(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAllWithCount(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<int> count(
          {Object? column, WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.countAsync(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sumAsync(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avgAsync(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.minAsync(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.maxAsync(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<User?> watchOne(Object id, {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<User>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

const _$SQFlowPostSchema = """
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE INDEX posts_user_id_idx ON posts(user_id);

CREATE TRIGGER update_posts_timestamp
AFTER UPDATE ON posts
FOR EACH ROW
BEGIN
    UPDATE posts SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowPostTable extends Table<Post> {
  _$SQFlowPostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: Post, paranoid: Table.detectSoftDelete(schema));
}

/// Post table schema
final postsTable = _$SQFlowPostTable(
  schema: _$SQFlowPostSchema,
  name: 'posts',
  fromJson: _$SQFlowPostFromJson,
  relationships: const [BelongsTo(model: 'users', foreignKey: 'user_id')],
  columns: const [
    'id',
    'title',
    'user_id',
    'created_at',
    'updated_at',
    'deleted_at'
  ],
  primaryKey: 'id',
  timestamps: true,
);

mixin _$SQFlowPostMixin {
  Map<String, dynamic> toJson() => _$SQFlowPostToJson(this as Post);

  @override
  String toString() => _$SQFlowPostToString(this as Post);
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  User? _$user;
  User? get user => _$user;
}

Map<String, dynamic> _$SQFlowPostToJson(Post instance) {
  final postJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'title': _$SQFlowToJsonValue(instance.title),
    'user_id': _$SQFlowToJsonValue(instance.userId),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
    'deleted_at': _$SQFlowToJsonValue(instance.deletedAt),
  };
  _$validatePost(postJson, tableName: 'posts');

  return postJson;
}

String _$SQFlowPostToString(Post instance) {
  return """
Post(
  id: ${instance.id},
  title: ${instance.title},
  userId: ${instance.userId},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
  deletedAt: ${instance.deletedAt},
  user: ${instance.user},
)""";
}

extension SQFlowPostExt on Post {
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

void _$validatePost(Map<String, dynamic> json, {required String tableName}) {}

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

/// Pluralized service for Post
class Posts {
  static const SqflowColumn<int> id = SqflowColumn<int>('id');
  static const SqflowColumn<String> title = SqflowColumn<String>('title');
  static const SqflowColumn<String> userId = SqflowColumn<String>('user_id');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');
  static const SqflowColumn<DateTime> deletedAt =
      SqflowColumn<DateTime>('deleted_at');

  static SqflowCore<Post> get _service =>
      SqflowCore<Post>(dbManager: appDb, table: postsTable);

  static SqflowQuery<Post> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<Post> get query => _service.query;

  static Future<int> insert(Post item, {DatabaseExecutor? executor}) =>
      _service.insertAsync(item, executor: executor);
  static Future<int> update(Post item, {DatabaseExecutor? executor}) =>
      _service.updateAsync(item, executor: executor);
  static Future<void> upsert(Post item, {DatabaseExecutor? executor}) =>
      _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<Post> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<Post> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<Post> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatchAsync(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatchAsync(ids, force: force, executor: executor);
  static Future<int> restoreBatch(List<Object> ids,
          {DatabaseExecutor? executor}) =>
      _service.restoreBatchAsync(ids, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.existsAsync(id, withDeleted: withDeleted, executor: executor);

  static Future<Post?> read(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAsync(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<Post>> readAll(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAll(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<ResultWithCount<Post>> readAllWithCount(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAllWithCount(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<int> count(
          {Object? column, WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.countAsync(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sumAsync(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avgAsync(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.minAsync(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.maxAsync(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<Post?> watchOne(Object id, {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<Post>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

const _$SQFlowProfileSchema = """
CREATE TABLE profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bio TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE UNIQUE INDEX profiles_user_id_idx ON profiles(user_id);

CREATE TRIGGER update_profiles_timestamp
AFTER UPDATE ON profiles
FOR EACH ROW
BEGIN
    UPDATE profiles SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowProfileTable extends Table<Profile> {
  _$SQFlowProfileTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: Profile, paranoid: Table.detectSoftDelete(schema));
}

/// Profile table schema
final profilesTable = _$SQFlowProfileTable(
  schema: _$SQFlowProfileSchema,
  name: 'profiles',
  fromJson: _$SQFlowProfileFromJson,
  relationships: const [BelongsTo(model: 'users', foreignKey: 'user_id')],
  columns: const ['id', 'bio', 'user_id', 'created_at', 'updated_at'],
  primaryKey: 'id',
  timestamps: true,
);

mixin _$SQFlowProfileMixin {
  Map<String, dynamic> toJson() => _$SQFlowProfileToJson(this as Profile);

  @override
  String toString() => _$SQFlowProfileToString(this as Profile);
  DateTime? createdAt;
  DateTime? updatedAt;
  User? _$user;
  User? get user => _$user;
}

Map<String, dynamic> _$SQFlowProfileToJson(Profile instance) {
  final profileJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'bio': _$SQFlowToJsonValue(instance.bio),
    'user_id': _$SQFlowToJsonValue(instance.userId),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };
  _$validateProfile(profileJson, tableName: 'profiles');

  return profileJson;
}

String _$SQFlowProfileToString(Profile instance) {
  return """
Profile(
  id: ${instance.id},
  bio: ${instance.bio},
  userId: ${instance.userId},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
  user: ${instance.user},
)""";
}

extension SQFlowProfileExt on Profile {
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

void _$validateProfile(Map<String, dynamic> json,
    {required String tableName}) {}

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

/// Pluralized service for Profile
class Profiles {
  static const SqflowColumn<int> id = SqflowColumn<int>('id');
  static const SqflowColumn<String> bio = SqflowColumn<String>('bio');
  static const SqflowColumn<String> userId = SqflowColumn<String>('user_id');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');

  static SqflowCore<Profile> get _service =>
      SqflowCore<Profile>(dbManager: appDb, table: profilesTable);

  static SqflowQuery<Profile> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<Profile> get query => _service.query;

  static Future<int> insert(Profile item, {DatabaseExecutor? executor}) =>
      _service.insertAsync(item, executor: executor);
  static Future<int> update(Profile item, {DatabaseExecutor? executor}) =>
      _service.updateAsync(item, executor: executor);
  static Future<void> upsert(Profile item, {DatabaseExecutor? executor}) =>
      _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<Profile> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<Profile> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<Profile> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatchAsync(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatchAsync(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.existsAsync(id, withDeleted: withDeleted, executor: executor);

  static Future<Profile?> read(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAsync(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<Profile>> readAll(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAll(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<ResultWithCount<Profile>> readAllWithCount(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAllWithCount(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<int> count(
          {Object? column, WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.countAsync(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sumAsync(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avgAsync(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.minAsync(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.maxAsync(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<Profile?> watchOne(Object id, {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<Profile>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

const _$SQFlowOrderSchema = """
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  total INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE INDEX orders_user_id_idx ON orders(user_id);

CREATE TRIGGER update_orders_timestamp
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    UPDATE orders SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowOrderTable extends Table<Order> {
  _$SQFlowOrderTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: Order, paranoid: Table.detectSoftDelete(schema));
}

/// Order table schema
final ordersTable = _$SQFlowOrderTable(
  schema: _$SQFlowOrderSchema,
  name: 'orders',
  fromJson: _$SQFlowOrderFromJson,
  relationships: const [BelongsTo(model: 'users', foreignKey: 'user_id')],
  columns: const [
    'id',
    'total',
    'user_id',
    'created_at',
    'updated_at',
    'deleted_at'
  ],
  primaryKey: 'id',
  timestamps: true,
);

mixin _$SQFlowOrderMixin {
  Map<String, dynamic> toJson() => _$SQFlowOrderToJson(this as Order);

  @override
  String toString() => _$SQFlowOrderToString(this as Order);
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  User? _$user;
  User? get user => _$user;
}

Map<String, dynamic> _$SQFlowOrderToJson(Order instance) {
  final orderJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'total': _$SQFlowToJsonValue(instance.total),
    'user_id': _$SQFlowToJsonValue(instance.userId),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
    'deleted_at': _$SQFlowToJsonValue(instance.deletedAt),
  };
  _$validateOrder(orderJson, tableName: 'orders');

  return orderJson;
}

String _$SQFlowOrderToString(Order instance) {
  return """
Order(
  id: ${instance.id},
  total: ${instance.total},
  userId: ${instance.userId},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
  deletedAt: ${instance.deletedAt},
  user: ${instance.user},
)""";
}

extension SQFlowOrderExt on Order {
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

void _$validateOrder(Map<String, dynamic> json, {required String tableName}) {}

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

/// Pluralized service for Order
class Orders {
  static const SqflowColumn<int> id = SqflowColumn<int>('id');
  static const SqflowColumn<int> total = SqflowColumn<int>('total');
  static const SqflowColumn<String> userId = SqflowColumn<String>('user_id');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');
  static const SqflowColumn<DateTime> deletedAt =
      SqflowColumn<DateTime>('deleted_at');

  static SqflowCore<Order> get _service =>
      SqflowCore<Order>(dbManager: appDb, table: ordersTable);

  static SqflowQuery<Order> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<Order> get query => _service.query;

  static Future<int> insert(Order item, {DatabaseExecutor? executor}) =>
      _service.insertAsync(item, executor: executor);
  static Future<int> update(Order item, {DatabaseExecutor? executor}) =>
      _service.updateAsync(item, executor: executor);
  static Future<void> upsert(Order item, {DatabaseExecutor? executor}) =>
      _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<Order> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<Order> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<Order> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatchAsync(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatchAsync(ids, force: force, executor: executor);
  static Future<int> restoreBatch(List<Object> ids,
          {DatabaseExecutor? executor}) =>
      _service.restoreBatchAsync(ids, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.existsAsync(id, withDeleted: withDeleted, executor: executor);

  static Future<Order?> read(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAsync(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<Order>> readAll(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAll(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<ResultWithCount<Order>> readAllWithCount(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAllWithCount(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<int> count(
          {Object? column, WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.countAsync(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sumAsync(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avgAsync(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.minAsync(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.maxAsync(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<Order?> watchOne(Object id, {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<Order>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
