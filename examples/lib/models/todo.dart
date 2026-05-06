import 'package:sqflow_platform_interface/sqflow_platform_interface.dart';

part 'todo.sql.g.dart';

@Schema(
  tableName: 'categories',
  relationships: [
    HasMany(model: 'tasks', foreignKey: 'category_id'),
  ],
)
class Category extends Model with _$SQFlowCategoryMixin {
  @ID()
  @override
  final String id;

  @Column()
  final String name;

  @Column()
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
  @ID( autoIncrement: true)
  @override
  final int id;

  @Column()
  final String title;

  @Column( defaultValue: false)
  final bool isCompleted;

  @Column()
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
