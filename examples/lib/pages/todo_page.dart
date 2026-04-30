import 'package:flutter/material.dart';
import 'package:sqflow_core/sqflow_core.dart' hide Column;
import 'package:sqflow_platform_interface/sqflow_platform_interface.dart' as pi;
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/todo.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _categoryService = SqflowCore<Category>(
    dbManager: todoDatabase,
    table: categoriesTable,
  );
  final _taskService = SqflowCore<Task>(
    dbManager: todoDatabase,
    table: tasksTable,
  );

  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    // Eager load tasks for each category
    final result = await _categoryService.readAll(
      include: [pi.Includable.model<Task>()],
    );
    
    // If no categories, seed some
    if (result.data.isEmpty) {
      await _seedData();
      final seeded = await _categoryService.readAll(
        include: [pi.Includable.model<Task>()],
      );
      _categories = seeded.data;
    } else {
      _categories = result.data;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _seedData() async {
    final categories = [
      Category(id: const Uuid().v4(), name: 'Work', color: '0xFF6366F1'),
      Category(id: const Uuid().v4(), name: 'Personal', color: '0xFFEC4899'),
      Category(id: const Uuid().v4(), name: 'Shopping', color: '0xFF10B981'),
    ];

    for (final cat in categories) {
      await _categoryService.upsertAsync(cat);
      // Add one sample task per category
      await _taskService.upsertAsync(Task(
        id: 0,
        title: 'Sample task for ${cat.name}',
        categoryId: cat.id,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_categories.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No Categories Yet')),
            )
          else
            _buildCategoryGrid(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        label: const Text('Add Category'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF6366F1),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My Workspace',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = _categories[index];
            return _CategoryCard(
              category: category,
              onTap: () => _openTasks(category),
            );
          },
          childCount: _categories.length,
        ),
      ),
    );
  }

  void _addCategory() {
    // Implementation for adding category
  }

  void _openTasks(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasksPage(category: category),
      ),
    ).then((_) => _refreshData());
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(category.color));
    final taskCount = category.tasks.length;
    final completedCount = category.tasks.where((t) => t.isCompleted).length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$taskCount Tasks',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            if (taskCount > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completedCount / taskCount,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TasksPage extends StatefulWidget {
  final Category category;
  const TasksPage({super.key, required this.category});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _taskService = SqflowCore<Task>(
    dbManager: todoDatabase,
    table: tasksTable,
  );

  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final result = await _taskService.readAll(
      where: WhereBuilder().eq('category_id', widget.category.id),
      sort: SortBuilder().desc('createdAt'),
    );
    _tasks = result.data;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(widget.category.color));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('No tasks in this category'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (val) => _toggleTask(task, val!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteTask(task),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: color,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _toggleTask(Task task, bool completed) async {
    await _taskService.updateAsync(Task(
      id: task.id,
      title: task.title,
      categoryId: task.categoryId,
      isCompleted: completed,

    ));
    _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    await _taskService.deleteAsync(task.id);
    _loadTasks();
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter task title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _taskService.upsertAsync(Task(
                  id: 0,
                  title: controller.text,
                  categoryId: widget.category.id,
                ));
                if (mounted) Navigator.pop(context);
                _loadTasks();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
