import 'package:flutter/material.dart';
import 'package:sqflow_core/sqflow_core.dart';
import 'package:uuid/uuid.dart';
import 'models/user.dart';

void main() {
  runApp(const SqflowReactivityApp());
}

class SqflowReactivityApp extends StatelessWidget {
  const SqflowReactivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sqflow Reactivity Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late final DB db;
  late final SqflowCore<User> userService;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    db = DB.autoVersion(
      databaseName: 'reactivity_demo.db',
      tables: [usersTable],
    );
    userService = SqflowCore<User>(dbManager: db, table: usersTable);

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<List<User>>(
            stream: userService.watchAll(limit: 1000),
            builder: (context, snapshot) {
              print('Snapshot: ${snapshot.data?.length ?? 0}');
              return Text('Sqflow Reactivity (${snapshot.data?.length ?? 0})');
            }),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: 'Batch Insert (Transaction)',
            onPressed: _performBatchInsert,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: () => userService.deleteBatchAsync(
                []), // Deletes all if empty where? No, need to be careful
          ),
        ],
      ),
      body: StreamBuilder<List<User>>(
        // THE MAGIC: This stream automatically updates when DB changes
        stream: userService.watchAll(
          limit: 1000,
          sort: SortBuilder().desc('created_at'),
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: SelectableText('Error: ${snapshot.error}\n\nStacktrace: ${snapshot.stackTrace}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text('No users yet. Tap + to add one!'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text((index + 1).toString())),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _updateUser(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => userService.deleteAsync(user.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addUser() async {
    final id = const Uuid().v4();
    await userService.insertAsync(User(
      id: id,
      firstName: 'New',
      lastName: 'User ${id.substring(0, 4)}',
      email: 'user_$id@example.com',
      phone: '123456',
      gender: 'Other',
      city: 'Demo City',
      country: 'Demo Country',
      address: 'Demo St',
    ));
  }

  Future<void> _updateUser(User user) async {
    await userService.updateAsync(user.copyWith(
      firstName: '${user.firstName} (Updated)',
    ));
  }

  Future<void> _performBatchInsert() async {
    // Demonstrates that StreamBuilder updates only ONCE after transaction
    await db.transaction((txn) async {
      for (int i = 0; i < 3; i++) {
        final id = const Uuid().v4();
        await userService.insertAsync(
          User(
            id: id,
            firstName: 'Batch',
            lastName: 'User $i',
            email: 'batch_$id@example.com',
            phone: '000000',
            gender: 'Other',
            city: 'Batch City',
            country: 'Batch Country',
            address: 'Batch St',
          ),
          executor: txn,
        );
        // Add a tiny delay to simulate heavy work
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch insert completed!')),
      );
    }
  }
}
