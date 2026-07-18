import 'dart:async';

import 'package:flutter/material.dart';

import '../phorm_service.dart';

/// Query Monitor: live feed of executed SQL queries.
class QueriesTab extends StatefulWidget {
  const QueriesTab({super.key});

  @override
  State<QueriesTab> createState() => _QueriesTabState();
}

class _QueriesTabState extends State<QueriesTab> {
  static const int _maxEntries = 1000;

  final List<QueryLogEntry> _entries = [];
  StreamSubscription<QueryLogEntry>? _sub;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _sub = PhormService.instance.queryStream.listen((entry) {
      if (_paused) return;
      setState(() {
        _entries.insert(0, entry);
        if (_entries.length > _maxEntries) _entries.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Color _durationColor(QueryLogEntry entry) {
    if (entry.error != null) return Colors.red;
    if (entry.executionTimeMs < 5) return Colors.green;
    if (entry.executionTimeMs < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                tooltip: _paused ? 'Resume' : 'Pause',
                onPressed: () => setState(() => _paused = !_paused),
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear',
                onPressed: () => setState(_entries.clear),
              ),
              const Spacer(),
              Text('${_entries.length} queries'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _entries.isEmpty
              ? const Center(
                  child: Text('Run queries in the app to see them here.'),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 70,
                        child: Text(
                          '${entry.executionTimeMs.toStringAsFixed(1)} ms',
                          style: TextStyle(color: _durationColor(entry)),
                        ),
                      ),
                      title: Text(
                        entry.sql,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      subtitle: entry.error != null
                          ? Text('Error: ${entry.error}')
                          : (entry.parameters != null
                              ? Text('Args: ${entry.parameters}')
                              : null),
                      trailing: Text(entry.dbId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
