import 'package:flutter/material.dart';

import '../phorm_service.dart';

/// Migrations: applied migration history from `__phorm_migrations`.
class MigrationsTab extends StatefulWidget {
  const MigrationsTab({super.key, required this.dbId});

  final String dbId;

  @override
  State<MigrationsTab> createState() => _MigrationsTabState();
}

class _MigrationsTabState extends State<MigrationsTab> {
  List<Map<String, dynamic>> _applied = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MigrationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dbId != widget.dbId) _load();
  }

  Future<void> _load() async {
    try {
      final result = await PhormService.instance.getMigrations(widget.dbId);
      setState(() {
        _applied = (result['applied'] as List? ?? [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_applied.isEmpty) {
      return const Center(child: Text('No applied migrations recorded.'));
    }
    return ListView(
      children: [
        for (final migration in _applied)
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              child: Text('${migration['version'] ?? '?'}'),
            ),
            title: Text('${migration['description'] ?? 'Migration'}'),
            subtitle: Text(
              [
                if (migration['applied_at'] != null)
                  'applied: ${migration['applied_at']}',
                if (migration['hash'] != null) 'hash: ${migration['hash']}',
              ].join('  ·  '),
            ),
          ),
      ],
    );
  }
}
