// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'user.dart';

const _$SQFlowUserSchema = """
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  first_name TEXT NOT NULL CONSTRAINT first_name_length CHECK(LENGTH(first_name) BETWEEN 2 AND 50),
  last_name TEXT NOT NULL CONSTRAINT last_name_length CHECK(LENGTH(last_name) BETWEEN 2 AND 50),
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL CONSTRAINT phone_length CHECK(LENGTH(phone) BETWEEN 6 AND 15),
  birth_date TEXT,
  age INTEGER,
  gender TEXT NOT NULL CONSTRAINT gender_check CHECK(gender IN ('M', 'F', 'Other')),
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  address TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_verified INTEGER NOT NULL DEFAULT 0,
  metadata TEXT,
  password TEXT NOT NULL,
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
    'metadata',
    'password',
    'created_at',
    'updated_at',
    'deleted_at'
  ],
  timestamps: true,
);

mixin _$SQFlowUserMixin {
  Map<String, dynamic> toJson() => _$SQFlowUserToJson(this as User);

  @override
  String toString() => _$SQFlowUserToString(this as User);
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
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
    'metadata': _$SQFlowToJsonValue(instance.metadata != null ? const JsonMapConverter().toSql(instance.metadata!) : null),
    'password': _$SQFlowToJsonValue(const PasswordConverter().toSql(instance.password)),
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
  posts: ${instance.posts},
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
  metadata: ${instance.metadata},
  password: ${instance.password},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
  deletedAt: ${instance.deletedAt},
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
    String? address,
    String? birthDate,
    int? age,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? metadata,
    String? password,
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
      metadata: metadata ?? this.metadata,
      password: password ?? this.password,
      posts: posts ?? this.posts,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..deletedAt = deletedAt ?? this.deletedAt;
  }
}

void _$validateUser(Map<String, dynamic> json, {required String tableName}) {
  if (!const LengthValidator(min: 2, max: 50, constraint: "first_name_length").isValid(json['first_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'first_name',
      message: 'Value "${json['first_name']}" failed validation',
      constraint: 'first_name_length',
    );
  }
  if (!const NotEmptyValidator().isValid(json['first_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'first_name',
      message: 'Value "${json['first_name']}" failed validation',
    );
  }
  if (!const LengthValidator(min: 2, max: 50, constraint: "last_name_length").isValid(json['last_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'last_name',
      message: 'Value "${json['last_name']}" failed validation',
      constraint: 'last_name_length',
    );
  }
  if (!const NotEmptyValidator().isValid(json['last_name'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'last_name',
      message: 'Value "${json['last_name']}" failed validation',
    );
  }
  if (!const EmailValidator(constraint: "email_format").isValid(json['email'])) {
    throw SqflowJSONValidatorException(
      table: tableName,
      column: 'email',
      message: 'Value "${json['email']}" failed validation',
      constraint: 'email_format',
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
  if (!const LengthValidator(min: 6, max: 15, constraint: "phone_length").isValid(json['phone'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'phone',
      message: 'Value "${json['phone']}" failed validation',
      constraint: 'phone_length',
    );
  }
  if (!const RegExpValidator("\\d{4}-\\d{2}-\\d{2}", constraint: "date_format").isValid(json['birth_date'])) {
    throw SqflowJSONValidatorException(
      table: tableName,
      column: 'birth_date',
      message: 'Value "${json['birth_date']}" failed validation',
      constraint: 'date_format',
    );
  }
  if (!const ContainsValidator(["M", "F", "Other"], constraint: "gender_check").isValid(json['gender'])) {
    throw SqflowCHECKValidatorException(
      table: tableName,
      column: 'gender',
      message: 'Value "${json['gender']}" failed validation',
      constraint: 'gender_check',
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
    address: json['address'] as String,
    birthDate: json['birth_date'] as String?,
    age: json['age'] as int?,
    isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active'] as int?) == 1,
    isVerified: json['is_verified'] is bool ? json['is_verified'] as bool : (json['is_verified'] as int?) == 1,
    metadata: json['metadata'] != null ? const JsonMapConverter().fromSql(json['metadata'] as String) : null,
    password: const PasswordConverter().fromSql(json['password'] as String),
    posts: json['posts'] != null ? (json['posts'] as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList() : [],
  )
    ..createdAt = json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null
    ..updatedAt = json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null
    ..deletedAt = json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null;
  return instance;
}

/// Pluralized service for User
class Users {
  static const SqflowColumn<String> id = SqflowColumn<String>('id');
  static const SqflowColumn<String> firstName = SqflowColumn<String>('first_name');
  static const SqflowColumn<String> lastName = SqflowColumn<String>('last_name');
  static const SqflowColumn<String> email = SqflowColumn<String>('email');
  static const SqflowColumn<String> phone = SqflowColumn<String>('phone');
  static const SqflowColumn<String> birthDate = SqflowColumn<String>('birth_date');
  static const SqflowColumn<int> age = SqflowColumn<int>('age');
  static const SqflowColumn<String> gender = SqflowColumn<String>('gender');
  static const SqflowColumn<String> city = SqflowColumn<String>('city');
  static const SqflowColumn<String> country = SqflowColumn<String>('country');
  static const SqflowColumn<String> address = SqflowColumn<String>('address');
  static const SqflowColumn<bool> isActive = SqflowColumn<bool>('is_active');
  static const SqflowColumn<bool> isVerified = SqflowColumn<bool>('is_verified');
  static const SqflowColumn<Map<String, dynamic>> metadata = SqflowColumn<Map<String, dynamic>>('metadata');
  static const SqflowColumn<String> password = SqflowColumn<String>('password');
  static const SqflowColumn<DateTime> createdAt = SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt = SqflowColumn<DateTime>('updated_at');
  static const SqflowColumn<DateTime> deletedAt = SqflowColumn<DateTime>('deleted_at');

  static SqflowCore<User> get _service => SqflowCore<User>(dbManager: appDb, table: usersTable);

  static SqflowQuery<User> where(SqflowCondition condition) => _service.where(condition);
  static SqflowQuery<User> get query => _service.query;

  static Future<int> insert(User item, {DatabaseExecutor? executor}) => _service.insertAsync(item, executor: executor);
  static Future<int> update(User item, {DatabaseExecutor? executor}) => _service.updateAsync(item, executor: executor);
  static Future<void> upsert(User item, {DatabaseExecutor? executor}) => _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id, {bool force = false, DatabaseExecutor? executor}) => _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) => _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<User> items, {DatabaseExecutor? executor}) => _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<User> items, {DatabaseExecutor? executor}) => _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<User> items, {DatabaseExecutor? executor}) => _service.upsertBatchAsync(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids, {bool force = false, DatabaseExecutor? executor}) => _service.deleteBatchAsync(ids, force: force, executor: executor);
  static Future<int> restoreBatch(List<Object> ids, {DatabaseExecutor? executor}) => _service.restoreBatchAsync(ids, executor: executor);

  static Future<bool> exists(Object id, {bool withDeleted = false, DatabaseExecutor? executor}) => _service.existsAsync(id, withDeleted: withDeleted, executor: executor);

  static Future<User?> read(Object id, {List<String>? columns, Attributes? attributes, bool withDeleted = false, List<Includable>? include, DatabaseExecutor? executor}) =>
      _service.readAsync(id, columns: columns, attributes: attributes, withDeleted: withDeleted, include: include, executor: executor);

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
          limit: limit, offset: offset, where: where, sort: sort, columns: columns, attributes: attributes, withDeleted: withDeleted, onlyDeleted: onlyDeleted, include: include, executor: executor);

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
          limit: limit, offset: offset, where: where, sort: sort, columns: columns, attributes: attributes, withDeleted: withDeleted, onlyDeleted: onlyDeleted, include: include, executor: executor);

  static Future<int> count({Object? column, WhereBuilder? where, DatabaseExecutor? executor}) => _service.countAsync(column: column, where: where, executor: executor);
  static Future<num> sum(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.sumAsync(column, where: where, executor: executor);
  static Future<num> avg(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.avgAsync(column, where: where, executor: executor);
  static Future<num> min(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.minAsync(column, where: where, executor: executor);
  static Future<num> max(Object column, {WhereBuilder? where, DatabaseExecutor? executor}) => _service.maxAsync(column, where: where, executor: executor);

  static Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) => _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<User?> watchOne(Object id, {List<Includable>? include}) => _service.watchOne(id, include: include);
  static Stream<List<User>> watchAll({WhereBuilder? where, List<Includable>? include, SortBuilder? sort, int? limit}) => _service.watchAll(where: where, include: include, sort: sort, limit: limit);
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
