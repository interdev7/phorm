import 'package:flutter/material.dart';

import 'phorm_service.dart';
import 'tabs/inspector_tab.dart';
import 'tabs/migrations_tab.dart';
import 'tabs/queries_tab.dart';
import 'tabs/streams_tab.dart';

/// Root widget of the Phorm Studio DevTools panel.
class PhormStudioPanel extends StatefulWidget {
  const PhormStudioPanel({super.key});

  @override
  State<PhormStudioPanel> createState() => _PhormStudioPanelState();
}

class _PhormStudioPanelState extends State<PhormStudioPanel> {
  List<Map<String, dynamic>> _databases = const [];
  String _dbId = 'main';
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    PhormService.instance.startListening();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    try {
      final databases = await PhormService.instance.listDatabases();
      setState(() {
        _databases = databases;
        _connectionError = null;
        if (databases.isNotEmpty &&
            !databases.any((d) => d['dbId'] == _dbId)) {
          _dbId = databases.first['dbId'] as String;
        }
      });
    } catch (e) {
      setState(() => _connectionError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Phorm Studio could not reach the phorm_devtools bridge.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure the app calls enablePhormDevtools(db) and runs in debug mode.',
            ),
            const SizedBox(height: 8),
            Text(_connectionError!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDatabases,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              const Text(
                'Phorm Studio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              if (_databases.length > 1)
                DropdownButton<String>(
                  value: _dbId,
                  items: [
                    for (final db in _databases)
                      DropdownMenuItem(
                        value: db['dbId'] as String,
                        child: Text(db['label'] as String? ?? 'db'),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _dbId = value ?? _dbId),
                ),
              const Expanded(
                child: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Database Inspector'),
                    Tab(text: 'Query Monitor'),
                    Tab(text: 'Migrations'),
                    Tab(text: 'Reactivity'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reload databases',
                onPressed: _loadDatabases,
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                InspectorTab(dbId: _dbId),
                const QueriesTab(),
                MigrationsTab(dbId: _dbId),
                StreamsTab(dbId: _dbId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
