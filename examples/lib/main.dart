import 'package:flutter/material.dart';
import 'package:sqflow_core/sqflow_core.dart';
import 'package:sqflow_example/example_reactivity.dart';
import 'package:sqflow_example/models/todo.dart';
import 'package:sqflow_example/pages/todo_page.dart';

// Initialize database with new Todo tables
final todoDatabase = DB.autoVersion(
  databaseName: 'todo_app.db',
  tables: [categoriesTable, tasksTable],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SqflowReactivityApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlow Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: const SqflowReactivityApp(),
    );
  }
}
