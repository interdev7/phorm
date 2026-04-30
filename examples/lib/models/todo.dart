import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

part 'todo.sql.g.dart';

@Schema(
  tableName: 'categories',
  relationships: [
    HasMany(model: 'tasks', foreignKey: 'category_id'),
  ],
)
class Category extends Model with _$SQFlowCategoryMixin {
  @ID(type: TEXT())
  @override
  final String id;

  @Column(type: TEXT())
  final String name;

  @Column(type: TEXT())
  final String color;

  Category({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$SQFlowCategoryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SQFlowCategoryToJson();
}

@Schema(
  tableName: 'tasks',
  paranoid: true,
  relationships: [
    BelongsTo(model: 'categories', foreignKey: 'category_id'),
  ],
)
class Task extends Model with _$SQFlowTaskMixin {
  @ID(type: INTEGER(), autoIncrement: true)
  @override
  final int id;

  @Column(type: TEXT())
  final String title;

  @Column(type: INTEGER(), defaultValue: false)
  final bool isCompleted;

  @Column(type: TEXT())
  final String categoryId;


  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.categoryId,
  });

  factory Task.fromJson(Map<String, dynamic> json) =>
      _$SQFlowTaskFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SQFlowTaskToJson();
}
