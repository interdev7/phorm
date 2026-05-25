import 'package:phorm/phorm.dart';
import 'package:phorm_sqlite/phorm_sqlite.dart';
import 'package:phorm_example/db.dart';

part 'todo.sql.g.dart';

@Schema(
  tableName: 'categories',
  relationships: [
    HasMany(model: 'tasks', foreignKey: 'category_id'),
  ],
)
class Category extends Model with _$SQFlowCategoryMixin {
  @ID()
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
}

@Schema(
  tableName: 'tasks',
  paranoid: true,
  relationships: [
    BelongsTo(model: 'categories', foreignKey: 'category_id'),
  ],
)
class Task extends Model with _$SQFlowTaskMixin {
  @ID(autoIncrement: true)
  final int id;

  @Column()
  final String title;

  @Column(defaultValue: false)
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
}
