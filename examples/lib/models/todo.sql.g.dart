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
  created_at TEXT,
  updated_at TEXT
);


""";

class _$SQFlowCategoryTable extends Table<Category> {
  _$SQFlowCategoryTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: Category, paranoid: Table.detectSoftDelete(schema));
}

/// Category table schema
final categoriesTable = _$SQFlowCategoryTable(
  schema: _$SQFlowCategorySchema,
  name: 'categories',
  fromJson: Category.fromJson,
  relationships: const [
    HasMany(model: 'tasks', foreignKey: 'category_id', localKey: 'id')
  ],
);

mixin _$SQFlowCategoryMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  final List<Task> _$tasks = [];
  List<Task> get tasks => _$tasks;
}

extension _$SQFlowCategorySqlExt on Category {
  Map<String, dynamic> _$SQFlowCategoryToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'name': _$SQFlowToJsonValue(name),
      'color': _$SQFlowToJsonValue(color),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
  }
}

Category _$SQFlowCategoryFromJson(Map<String, dynamic> json) {
  final instance = Category(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String,
  );
  instance.createdAt = json['created_at'] != null
      ? DateTime.parse(json['created_at'] as String)
      : null;
  instance.updatedAt = json['updated_at'] != null
      ? DateTime.parse(json['updated_at'] as String)
      : null;
  if (json['tasks'] != null) {
    instance.tasks.addAll((json['tasks'] as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList());
  }
  return instance;
}

const _$SQFlowTaskSchema = """
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,
  category_id TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  deleted_at TEXT
);


""";

class _$SQFlowTaskTable extends Table<Task> {
  _$SQFlowTaskTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: Task, paranoid: Table.detectSoftDelete(schema));
}

/// Task table schema
final tasksTable = _$SQFlowTaskTable(
  schema: _$SQFlowTaskSchema,
  name: 'tasks',
  fromJson: Task.fromJson,
  relationships: const [
    BelongsTo(model: 'categories', foreignKey: 'category_id', localKey: 'id')
  ],
);

mixin _$SQFlowTaskMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  Category? _$category;
  Category? get category => _$category;
}

extension _$SQFlowTaskSqlExt on Task {
  Map<String, dynamic> _$SQFlowTaskToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'title': _$SQFlowToJsonValue(title),
      'is_completed': _$SQFlowToJsonValue(isCompleted),
      'category_id': _$SQFlowToJsonValue(categoryId),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
      'deleted_at': _$SQFlowToJsonValue(deletedAt),
    };
  }
}

Task _$SQFlowTaskFromJson(Map<String, dynamic> json) {
  final instance = Task(
    id: json['id'] as int,
    title: json['title'] as String,
    isCompleted: json['is_completed'] is bool
        ? json['is_completed'] as bool
        : (json['is_completed'] as int?) == 1,
    categoryId: json['category_id'] as String,
  );
  instance.createdAt = json['created_at'] != null
      ? DateTime.parse(json['created_at'] as String)
      : null;
  instance.updatedAt = json['updated_at'] != null
      ? DateTime.parse(json['updated_at'] as String)
      : null;
  instance.deletedAt = json['deleted_at'] != null
      ? DateTime.parse(json['deleted_at'] as String)
      : null;
  instance._$category = json['categories'] != null
      ? Category.fromJson(json['categories'] as Map<String, dynamic>)
      : null;
  return instance;
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
