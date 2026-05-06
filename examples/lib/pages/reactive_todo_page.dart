import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflow_core/sqflow_core.dart' hide Column;
import 'package:sqflow_example/models/todo.dart';
import 'package:sqflow_example/main.dart';
import 'package:uuid/uuid.dart';

class ReactiveTodoPage extends StatefulWidget {
  const ReactiveTodoPage({super.key});

  @override
  State<ReactiveTodoPage> createState() => _ReactiveTodoPageState();
}

class _ReactiveTodoPageState extends State<ReactiveTodoPage>
    with SingleTickerProviderStateMixin {
  late SqflowCore<Category> _categoryService;
  late SqflowCore<Task> _taskService;
  late TabController _tabController;
  StreamSubscription<String>? _sub;

  List<Task> _tasks = [];
  List<Task> _deletedTasks = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;

  final _taskCtrl = TextEditingController();
  bool _isLoading = true;

  static const _defaultCategories = [
    ('Work', '#6C63FF'),
    ('Personal', '#11998E'),
    ('Learning', '#4FACFE'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _categoryService =
        SqflowCore<Category>(dbManager: appDb, table: categoriesTable);
    _taskService = SqflowCore<Task>(dbManager: appDb, table: tasksTable);
    _initData();
    _subscribeToChanges();
  }

  /// Demonstrates: DB.onTableChanged stream — real-time reactivity
  void _subscribeToChanges() {
    _sub = appDb.changeStream.listen((tableName) {
      if (tableName == 'tasks' || tableName == 'categories') {
        _loadTasks();
      }
    });
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    final cats = await _categoryService.readAll(limit: 100);
    if (cats.data.isEmpty) {
      await _seedCategories();
    } else {
      _categories = cats.data;
    }
    if (_categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
    }
    await _loadTasks();
    setState(() => _isLoading = false);
  }

  Future<void> _seedCategories() async {
    final uuid = const Uuid();
    for (final (name, color) in _defaultCategories) {
      await _categoryService
          .insertAsync(Category(id: uuid.v4(), name: name, color: color));
    }
    final cats = await _categoryService.readAll(limit: 100);
    _categories = cats.data;
  }

  Future<void> _loadTasks() async {
    if (_selectedCategoryId == null) return;
    // Active tasks filtered by category
    final active = await _taskService.readAll(
      limit: 200,
      where: WhereBuilder().eq('category_id', _selectedCategoryId!),
    );
    // Demonstrates: onlyDeleted — reads paranoid soft-deleted rows
    final deleted = await _taskService.readAll(
      limit: 200,
      onlyDeleted: true,
    );
    if (mounted) {
      setState(() {
        _tasks = active.data;
        _deletedTasks = deleted.data;
      });
    }
  }

  Future<void> _addTask() async {
    final title = _taskCtrl.text.trim();
    if (title.isEmpty || _selectedCategoryId == null) return;
    _taskCtrl.clear();
    await _taskService.insertAsync(
        Task(id: 0, title: title, categoryId: _selectedCategoryId!));
    // onTableChanged stream fires → _loadTasks() runs automatically
  }

  Future<void> _toggleComplete(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _taskService.updateAsync(updated);
  }

  Future<void> _softDelete(Task task) async {
    // paranoid: true → soft delete (sets deleted_at, does NOT remove row)
    await _taskService.deleteAsync(task.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        content: Text('Task moved to Recycle Bin',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF6C63FF),
          onPressed: () => _restore(task),
        ),
      ),
    );
  }

  Future<void> _restore(Task task) async {
    // Demonstrates: restoreAsync — clears deleted_at
    await _taskService.restoreAsync(task.id);
  }

  Future<void> _hardDelete(Task task) async {
    // force: true → actual DELETE FROM SQL, bypasses paranoid
    await _taskService.deleteAsync(task.id, force: true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    _taskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildCategoryPicker(),
                      _buildTabBar(),
                    ],
                  ),
                ),
              ],
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveList(),
                        _buildRecycleBin(),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAddTaskFab(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1A),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reactive Todos',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white)),
            Text('onTableChanged · Paranoid · Soft Delete · Restore',
                style: GoogleFonts.inter(fontSize: 9, color: Colors.white54)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFFC5C7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.checklist,
                  size: 64, color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final selected = _selectedCategoryId == cat.id;
          final color = _hexColor(cat.color);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryId = cat.id);
              _loadTasks();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.25)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? color : Colors.white.withOpacity(0.1),
                    width: selected ? 2 : 1),
              ),
              child: Center(
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(cat.name,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: selected ? color : Colors.white60,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.checklist, size: 15),
            const SizedBox(width: 6),
            Text('Active (${_tasks.length})'),
          ])),
          Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.delete_sweep_outlined, size: 15),
            const SizedBox(width: 6),
            Text('Bin (${_deletedTasks.length})'),
          ])),
        ],
      ),
    );
  }

  Widget _buildActiveList() {
    if (_tasks.isEmpty) {
      return _buildEmptyState(
          icon: Icons.task_alt,
          title: 'No tasks yet',
          subtitle: 'Add a task using the button below.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _tasks.length,
      itemBuilder: (_, i) => _buildTaskTile(_tasks[i]),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
      ),
      onDismissed: (_) => _softDelete(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: GestureDetector(
            onTap: () => _toggleComplete(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? const Color(0xFF00C896).withOpacity(0.2)
                    : Colors.transparent,
                border: Border.all(
                    color: task.isCompleted
                        ? const Color(0xFF00C896)
                        : Colors.white24,
                    width: 2),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Color(0xFF00C896))
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: task.isCompleted ? Colors.white38 : Colors.white,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('id: ${task.id}',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, color: Colors.white24)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFFF6B6B)),
            onPressed: () => _softDelete(task),
          ),
        ),
      ),
    );
  }

  Widget _buildRecycleBin() {
    if (_deletedTasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.delete_sweep_outlined,
        title: 'Recycle Bin is empty',
        subtitle:
            'Swipe tasks left to soft-delete them.\nThey appear here and can be restored.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFC5C7D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: const Color(0xFFFC5C7D).withOpacity(0.3)),
              ),
              child: Text('PARANOID MODE',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: const Color(0xFFFC5C7D),
                      fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text('deleted_at ≠ NULL',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, color: Colors.white24)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: _deletedTasks.length,
            itemBuilder: (_, i) => _buildDeletedTile(_deletedTasks[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildDeletedTile(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFC5C7D).withOpacity(0.15)),
      ),
      child: Row(children: [
        const Icon(Icons.restore_from_trash_outlined,
            size: 20, color: Color(0xFFFC5C7D)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white60,
                      decoration: TextDecoration.lineThrough)),
              if (task.deletedAt != null)
                Text('Deleted: ${task.deletedAt}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: Colors.white24)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _restore(task),
          icon: const Icon(Icons.restore, size: 15, color: Color(0xFF6C63FF)),
          label: Text('Restore',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF6C63FF))),
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever,
              size: 18, color: Color(0xFFFF6B6B)),
          tooltip: 'Hard delete (force: true)',
          onPressed: () => _hardDelete(task),
        ),
      ]),
    );
  }

  Widget _buildAddTaskFab() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: _taskCtrl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'New task…',
                hintStyle:
                    GoogleFonts.inter(color: Colors.white30, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
                filled: false,
              ),
              onSubmitted: (_) => _addTask(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addTask,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFC5C7D)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white24, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }
}
