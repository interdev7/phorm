import 'dart:async';

import 'package:flutter/material.dart';

import '../phorm_service.dart';

/// Reactivity: active watchOne/watchAll streams with dependencies.
class StreamsTab extends StatefulWidget {
  const StreamsTab({super.key, required this.dbId});

  final String dbId;

  @override
  State<StreamsTab> createState() => _StreamsTabState();
}

class _StreamsTabState extends State<StreamsTab> {
  List<Map<String, dynamic>> _streams = const [];
  Timer? _refreshTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final streams =
          await PhormService.instance.getActiveStreams(widget.dbId);
      if (!mounted) return;
      setState(() {
        _streams = streams;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_streams.isEmpty) {
      return const Center(
        child: Text('No active watchOne / watchAll streams.'),
      );
    }
    return ListView(
      children: [
        for (final stream in _streams)
          ListTile(
            dense: true,
            leading: Icon(
              stream['kind'] == 'watchOne' ? Icons.filter_1 : Icons.stream,
            ),
            title: Text(
              '${stream['kind']}(${stream['table']}'
              '${stream['primaryKey'] != null ? ', ${stream['primaryKey']}' : ''})',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Text(
              'depends on: ${(stream['dependencies'] as List).join(', ')}'
              '  ·  created: ${stream['createdAt']}',
            ),
            trailing: Chip(label: Text('${stream['emitCount']} emits')),
          ),
      ],
    );
  }
}
