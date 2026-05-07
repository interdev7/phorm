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
  DateTime? createdAt;
  DateTime? updatedAt;
  final List<Task> _$tasks = [];
  List<Task> get tasks => _$tasks;
}

extension SQFlowCategorySqlExt on Category {
  Map<String, dynamic> _$SQFlowCategoryToJson() {
    final categoryJson = {
      'id': _$SQFlowToJsonValue(id),
      'name': _$SQFlowToJsonValue(name),
      'color': _$SQFlowToJsonValue(color),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
    _$validateCategory(categoryJson, tableName: 'categories');

    return categoryJson;
  }

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

  String _$SQFlowCategoryToString() {
    return """
Category(
  id: $id,
  name: $name,
  color: $color,
  createdAt: $createdAt,
  updatedAt: $updatedAt,
  tasks: $tasks,
)""";
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

class CategoryTable {
  static const SqflowColumn<String> id = SqflowColumn<String>('id');
  static const SqflowColumn<String> name = SqflowColumn<String>('name');
  static const SqflowColumn<String> color = SqflowColumn<String>('color');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');
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
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  Category? _$category;
  Category? get category => _$category;
}

extension SQFlowTaskSqlExt on Task {
  Map<String, dynamic> _$SQFlowTaskToJson() {
    final taskJson = {
      'id': _$SQFlowToJsonValue(id),
      'title': _$SQFlowToJsonValue(title),
      'is_completed': _$SQFlowToJsonValue(isCompleted),
      'category_id': _$SQFlowToJsonValue(categoryId),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
      'deleted_at': _$SQFlowToJsonValue(deletedAt),
    };
    _$validateTask(taskJson, tableName: 'tasks');

    return taskJson;
  }

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

  String _$SQFlowTaskToString() {
    return """
Task(
  id: $id,
  title: $title,
  isCompleted: $isCompleted,
  categoryId: $categoryId,
  createdAt: $createdAt,
  updatedAt: $updatedAt,
  deletedAt: $deletedAt,
  category: $category,
)""";
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

class TaskTable {
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
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
