import 'package:flutter/material.dart';
import 'package:sqflow_core/sqflow_core.dart';

import 'models/user.dart';
import 'pages/users_page.dart';

final database = DB.autoVersion(
  databaseName: 'users.db',
  tables: [usersTableSchema],
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Database Test',
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
        home: const UsersPage());
  }
}
