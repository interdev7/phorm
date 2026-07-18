import 'package:flutter/material.dart';

import '../phorm_service.dart';

/// Database Inspector: table list on the left, row grid on the right.
class InspectorTab extends StatefulWidget {
  const InspectorTab({super.key, required this.dbId});

  final String dbId;

  @override
  State<InspectorTab> createState() => _InspectorTabState();
}

class _InspectorTabState extends State<InspectorTab> {
  List<Map<String, dynamic>> _tables = const [];
  String? _selected;
  List<Map<String, dynamic>> _rows = const [];
  List<String> _columns = const [];
  int _totalCount = 0;
  int _offset = 0;
  bool _includeDeleted = false;
  String _search = '';
  String? _orderBy;
  bool _orderDesc = false;
  String? _error;

  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void didUpdateWidget(InspectorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dbId != widget.dbId) {
      _selected = null;
      _loadTables();
    }
  }

  Future<void> _loadTables() async {
    try {
      final tables = await PhormService.instance.getTables(widget.dbId);
      setState(() {
        _tables = tables;
        _error = null;
      });
      if (_selected == null && tables.isNotEmpty) {
        _selectTable(tables.first);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _selectTable(Map<String, dynamic> table) {
    setState(() {
      _selected = table['name'] as String;
      _columns = (table['columns'] as List).cast<String>();
      _offset = 0;
      _orderBy = null;
    });
    _loadRows();
  }

  Future<void> _loadRows() async {
    final table = _selected;
    if (table == null) return;
    try {
      final result = await PhormService.instance.queryData(
        dbId: widget.dbId,
        table: table,
        limit: _pageSize,
        offset: _offset,
        includeDeleted: _includeDeleted,
        searchQuery: _search,
        orderBy: _orderBy,
        orderDir: _orderDesc ? 'desc' : 'asc',
      );
      setState(() {
        _rows = (result['rows'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        _totalCount = result['totalCount'] as int? ?? 0;
        _error = null;
        if (_columns.isEmpty && _rows.isNotEmpty) {
          _columns = _rows.first.keys.toList();
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 220,
          child: ListView(
            children: [
              for (final table in _tables)
                ListTile(
                  dense: true,
                  selected: table['name'] == _selected,
                  title: Text(table['name'] as String),
                  trailing: Text('${table['rowCount']}'),
                  onTap: () => _selectTable(table),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _toolbar(),
              const Divider(height: 1),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $_error'),
                )
              else
                Expanded(child: _grid()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolbar() {
    final page = _offset ~/ _pageSize + 1;
    final pages = (_totalCount / _pageSize).ceil().clamp(1, 1 << 31);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 16),
                hintText: 'Search…',
              ),
              onSubmitted: (value) {
                _search = value;
                _offset = 0;
                _loadRows();
              },
            ),
          ),
          const SizedBox(width: 12),
          Checkbox(
            value: _includeDeleted,
            onChanged: (value) {
              _includeDeleted = value ?? false;
              _loadRows();
            },
          ),
          const Text('Include soft deleted'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _offset >= _pageSize
                ? () {
                    _offset -= _pageSize;
                    _loadRows();
                  }
                : null,
          ),
          Text('$page / $pages  ($_totalCount rows)'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _offset + _pageSize < _totalCount
                ? () {
                    _offset += _pageSize;
                    _loadRows();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload rows',
            onPressed: _loadRows,
          ),
        ],
      ),
    );
  }

  Widget _grid() {
    if (_rows.isEmpty) return const Center(child: Text('No rows'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortColumnIndex:
              _orderBy == null ? null : _columns.indexOf(_orderBy!),
          sortAscending: !_orderDesc,
          columns: [
            for (final column in _columns)
              DataColumn(
                label: Text(column),
                onSort: (_, ascending) {
                  _orderBy = column;
                  _orderDesc = !ascending;
                  _loadRows();
                },
              ),
          ],
          rows: [
            for (final row in _rows)
              DataRow(
                cells: [
                  for (final column in _columns)
                    DataCell(Text('${row[column]}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
