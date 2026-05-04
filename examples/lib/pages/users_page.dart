import 'package:flutter/material.dart';
import 'package:sqflow_core/sqflow_core.dart' hide Column;
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../repositories/user.repository.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserRepository _repo = UserRepository();

  bool _showDeleted = false;
  bool _onlyDeleted = false;

  int _limit = 10;
  int _offset = 0;

  String _search = '';
  bool _sortAsc = true;

  late Future<ResultWithCount<User>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final where = WhereBuilder();

    if (_search.isNotEmpty) {
      where.orGroup((f) {
        f
          ..like('first_name', '%$_search%')
          ..like('last_name', '%$_search%')
          ..like('email', '%$_search%');
      });
    }

    _future = _repo.readAllWithCount(
      limit: _limit,
      offset: _offset,
      where: where.isEmpty ? null : where,
      sort: (_sortAsc
          ? SortBuilder().asc('created_at')
          : SortBuilder().desc('created_at')),
      withDeleted: _showDeleted,
      onlyDeleted: _onlyDeleted,
    );

    setState(() {});
  }

  Future<void> _addUser() async {
    await _openDialog();
  }

  Future<void> _editUser(User user) async {
    await _openDialog(user: user);
  }

  Future<void> _delete(User user) async {
    final confirm = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user'),
        content:
            Text('Are you sure you want to delete user ${user.firstName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('delete'),
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('delete_permanently'),
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                foregroundColor: Colors.white,
                backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (confirm == null) return;

    if (confirm == 'delete') {
      await _repo.deleteAsync(user.id);
      _load();
    } else if (confirm == 'delete_permanently') {
      await _repo.deleteAsync(user.id, force: true);
      _load();
    }
  }

  Future<void> _restore(User user) async {
    await _repo.restoreAsync(user.id);
    _load();
  }

  Future<void> _openDialog({User? user}) async {
    final firstNameCtrl = TextEditingController(text: user?.firstName);
    final lastNameCtrl = TextEditingController(text: user?.lastName);
    final emailCtrl = TextEditingController(text: user?.email);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user == null ? 'Add user' : 'Edit user'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name')),
            TextField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name')),
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              final firstName = firstNameCtrl.text.trim();
              final lastName = lastNameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (firstName.isEmpty || email.isEmpty) return;

              final entity = User(
                id: user?.id ?? const Uuid().v4(),
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: user?.phone ?? '',
                gender: user?.gender ?? 'Other',
                city: user?.city ?? '',
                country: user?.country ?? '',
                address: user?.address ?? '',
              );

              if (user == null) {
                await _repo.upsertAsync(entity);
              } else {
                await _repo.updateAsync(entity);
              }

              if (mounted) Navigator.pop(context);
              _load();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _testExists(User user) async {
    final exists = await _repo.existsAsync(user.id);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('exists(${user.id}) = $exists')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              _sortAsc = !_sortAsc;
              _load();
            },
          ),
          IconButton(
            icon: Icon(_showDeleted ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Show deleted',
            onPressed: () {
              _showDeleted = !_showDeleted;
              _onlyDeleted = false;
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Only deleted',
            onPressed: () {
              _onlyDeleted = !_onlyDeleted;
              _showDeleted = true;
              _load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _addUser, child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search name or email'),
              onChanged: (v) {
                _search = v;
                _offset = 0;
                _load();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                final users = data.data;

                if (users.isEmpty) {
                  return const Center(child: Text('No users'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          final isDeleted = u.deletedAt != null;

                          return ListTile(
                            title: Text('${u.firstName} ${u.lastName}',
                                style: TextStyle(
                                    decoration: isDeleted
                                        ? TextDecoration.lineThrough
                                        : null)),
                            subtitle: Text(
                              '${u.email}\n'
                              'isActive: ${u.isActive}\n'
                              'created: ${u.createdAt}\n'
                              'updated: ${u.updatedAt}\n'
                              'deleted: ${u.deletedAt}',
                            ),
                            isThreeLine: true,
                            onTap: () => _editUser(u),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.info),
                                    onPressed: () => _testExists(u)),
                                if (isDeleted)
                                  IconButton(
                                      icon: const Icon(Icons.restore),
                                      onPressed: () => _restore(u))
                                else
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _delete(u)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 94),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Total: ${data.count}'),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _offset == 0
                                ? null
                                : () {
                                    _offset -= _limit;
                                    _load();
                                  },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: (_offset + _limit) >= data.count
                                ? null
                                : () {
                                    _offset += _limit;
                                    _load();
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
