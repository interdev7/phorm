// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'todo.dart';

const _$SQFlowCategorySchema = """
CREATE TABLE categories (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


CREATE TRIGGER update_categories_timestamp
AFTER UPDATE ON categories
FOR EACH ROW
BEGIN
    UPDATE categories SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowCategoryTable extends Table<Category> {
  _$SQFlowCategoryTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.timestamps = true,
  }) : super(type: Category, paranoid: Table.detectSoftDelete(schema));
}

/// Category table schema
final categoriesTable = _$SQFlowCategoryTable(
  schema: _$SQFlowCategorySchema,
  name: 'categories',
  fromJson: _$SQFlowCategoryFromJson,
  relationships: const [HasMany(model: 'tasks', foreignKey: 'category_id')],
  columns: const ['id', 'name', 'color', 'created_at', 'updated_at'],
  timestamps: true,
);

mixin _$SQFlowCategoryMixin {
  Map<String, dynamic> toJson() => _$SQFlowCategoryToJson(this as Category);

  @override
  String toString() => _$SQFlowCategoryToString(this as Category);
  DateTime? createdAt;
  DateTime? updatedAt;
  final List<Task> _$tasks = [];
  List<Task> get tasks => _$tasks;
}

Map<String, dynamic> _$SQFlowCategoryToJson(Category instance) {
  final categoryJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'name': _$SQFlowToJsonValue(instance.name),
    'color': _$SQFlowToJsonValue(instance.color),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };
  _$validateCategory(categoryJson, tableName: 'categories');

  return categoryJson;
}

String _$SQFlowCategoryToString(Category instance) {
  return """
Category(
  id: ${instance.id},
  name: ${instance.name},
  color: ${instance.color},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
  tasks: ${instance.tasks},
)""";
}

extension SQFlowCategoryExt on Category {
  Category copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

void _$validateCategory(Map<String, dynamic> json,
    {required String tableName}) {}

Category _$SQFlowCategoryFromJson(Map<String, dynamic> json) {
  final instance = Category(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null
    ..tasks.addAll(json['tasks'] != null
        ? (json['tasks'] as List)
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList()
        : []);
  return instance;
}

/// Pluralized service for Category
class Categories {
  static const SqflowColumn<String> id = SqflowColumn<String>('id');
  static const SqflowColumn<String> name = SqflowColumn<String>('name');
  static const SqflowColumn<String> color = SqflowColumn<String>('color');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');

  static SqflowCore<Category> get _service =>
      SqflowCore<Category>(dbManager: appDb, table: categoriesTable);

  static SqflowQuery<Category> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<Category> get query => _service.query;

  static Future<int> insert(Category item, {DatabaseExecutor? executor}) =>
      _service.insertAsync(item, executor: executor);
  static Future<int> update(Category item, {DatabaseExecutor? executor}) =>
      _service.updateAsync(item, executor: executor);
  static Future<void> upsert(Category item, {DatabaseExecutor? executor}) =>
      _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<Category> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<Category> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<Category> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatchAsync(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatchAsync(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.existsAsync(id, withDeleted: withDeleted, executor: executor);

  static Future<Category?> read(Object id,
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

  static Future<Result<Category>> readAll(
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

  static Future<ResultWithCount<Category>> readAllWithCount(
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
  static Stream<Category?> watch(Object id, {List<Includable>? include}) =>
      _service.watch(id, include: include);
  static Stream<List<Category>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

const _$SQFlowTaskSchema = """
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,
  category_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  FOREIGN KEY(category_id) REFERENCES categories(id)
);


CREATE TRIGGER update_tasks_timestamp
AFTER UPDATE ON tasks
FOR EACH ROW
BEGIN
    UPDATE tasks SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowTaskTable extends Table<Task> {
  _$SQFlowTaskTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.timestamps = true,
  }) : super(type: Task, paranoid: Table.detectSoftDelete(schema));
}

/// Task table schema
final tasksTable = _$SQFlowTaskTable(
  schema: _$SQFlowTaskSchema,
  name: 'tasks',
  fromJson: _$SQFlowTaskFromJson,
  relationships: const [
    BelongsTo(model: 'categories', foreignKey: 'category_id')
  ],
  columns: const [
    'id',
    'title',
    'is_completed',
    'category_id',
    'created_at',
    'updated_at',
    'deleted_at'
  ],
  timestamps: true,
);

mixin _$SQFlowTaskMixin {
  Map<String, dynamic> toJson() => _$SQFlowTaskToJson(this as Task);

  @override
  String toString() => _$SQFlowTaskToString(this as Task);
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  Category? _$category;
  Category? get category => _$category;
}

Map<String, dynamic> _$SQFlowTaskToJson(Task instance) {
  final taskJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'title': _$SQFlowToJsonValue(instance.title),
    'is_completed': _$SQFlowToJsonValue(instance.isCompleted),
    'category_id': _$SQFlowToJsonValue(instance.categoryId),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
    'deleted_at': _$SQFlowToJsonValue(instance.deletedAt),
  };
  _$validateTask(taskJson, tableName: 'tasks');

  return taskJson;
}

String _$SQFlowTaskToString(Task instance) {
  return """
Task(
  id: ${instance.id},
  title: ${instance.title},
  isCompleted: ${instance.isCompleted},
  categoryId: ${instance.categoryId},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
  deletedAt: ${instance.deletedAt},
  category: ${instance.category},
)""";
}

extension SQFlowTaskExt on Task {
  Task copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..deletedAt = deletedAt ?? this.deletedAt;
  }
}

void _$validateTask(Map<String, dynamic> json, {required String tableName}) {}

Task _$SQFlowTaskFromJson(Map<String, dynamic> json) {
  final instance = Task(
    id: json['id'] as int,
    title: json['title'] as String,
    isCompleted: json['is_completed'] is bool
        ? json['is_completed'] as bool
        : (json['is_completed'] as int?) == 1,
    categoryId: json['category_id'] as String,
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
    .._$category = json['categories'] != null
        ? Category.fromJson(json['categories'] as Map<String, dynamic>)
        : null;
  return instance;
}

/// Pluralized service for Task
class Tasks {
  static const SqflowColumn<int> id = SqflowColumn<int>('id');
  static const SqflowColumn<String> title = SqflowColumn<String>('title');
  static const SqflowColumn<bool> isCompleted =
      SqflowColumn<bool>('is_completed');
  static const SqflowColumn<String> categoryId =
      SqflowColumn<String>('category_id');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');
  static const SqflowColumn<DateTime> deletedAt =
      SqflowColumn<DateTime>('deleted_at');

  static SqflowCore<Task> get _service =>
      SqflowCore<Task>(dbManager: appDb, table: tasksTable);

  static SqflowQuery<Task> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<Task> get query => _service.query;

  static Future<int> insert(Task item, {DatabaseExecutor? executor}) =>
      _service.insertAsync(item, executor: executor);
  static Future<int> update(Task item, {DatabaseExecutor? executor}) =>
      _service.updateAsync(item, executor: executor);
  static Future<void> upsert(Task item, {DatabaseExecutor? executor}) =>
      _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<Task> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<Task> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<Task> items,
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

  static Future<Task?> read(Object id,
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

  static Future<Result<Task>> readAll(
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

  static Future<ResultWithCount<Task>> readAllWithCount(
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
  static Stream<Task?> watch(Object id, {List<Includable>? include}) =>
      _service.watch(id, include: include);
  static Stream<List<Task>> watchAll(
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
