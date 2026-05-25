import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phorm/phorm.dart' hide Column;
import 'package:phorm_example/models/user.dart';
import 'package:phorm_example/models/post.dart';
import 'package:uuid/uuid.dart';

class ReactivityShowcasePage extends StatefulWidget {
  const ReactivityShowcasePage({super.key});

  @override
  State<ReactivityShowcasePage> createState() => _ReactivityShowcasePageState();
}

class _ReactivityShowcasePageState extends State<ReactivityShowcasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Query Builder State
  String? _selectedCity;
  int _selectedMinAge = 18;
  String? _selectedGender;
  List<User> _queryResults = [];
  bool _isQueryRunning = false;
  String _generatedSql = '';

  // Reactive Watchers State
  User? _watcherSelectedUser;
  User? _deepUserCache;
  final StreamController<User?> _deepUserController =
      StreamController<User?>.broadcast();
  StreamSubscription<User?>? _deepUserSubscription;
  List<User>? _activeUsersCache;
  late final StreamController<List<User>> _activeUsersController =
      StreamController<List<User>>.broadcast();
  late final Stream<List<User>> _activeUsersStream =
      _activeUsersController.stream;
  StreamSubscription<List<User>>? _activeUsersSubscription;

  // Broadcasters for All Users list to support dropdown reactively
  List<User>? _allUsersCache;
  late final StreamController<List<User>> _allUsersController =
      StreamController<List<User>>.broadcast();
  late final Stream<List<User>> _allUsersStream = _allUsersController.stream;
  StreamSubscription<List<User>>? _allUsersSubscription;

  final _newPostTitleCtrl = TextEditingController();
  final _newPostContentCtrl = TextEditingController();

  // Transaction Buffering State
  int _streamEmissionsCount = 0;
  bool _isBufferingActionRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupStreams();
    _runQueryBuilder();
  }

  void _setupStreams() {
    // 1. Stream of Active Users (multicasted via broadcast controller to support TabBarView navigation)
    _activeUsersSubscription?.cancel();
    _activeUsersSubscription = Users.watchAll(
      where: WhereBuilder().eq('is_active', true),
    ).listen(
      (data) {
        _activeUsersCache = data;
        if (!_activeUsersController.isClosed) {
          _activeUsersController.add(data);
        }
      },
      onError: (err) {
        if (!_activeUsersController.isClosed) {
          _activeUsersController.addError(err);
        }
      },
    );

    // 2. Stream of All Users (multicasted to support dropdown selector and transaction buffering emissions)
    _allUsersSubscription?.cancel();
    _allUsersSubscription = Users.watchAll().listen(
      (data) {
        _allUsersCache = data;

        // Auto-select or update the active watcher user
        if (_watcherSelectedUser == null && data.isNotEmpty) {
          _watcherSelectedUser = data.first;
          _updateDeepUserStream();
        } else if (_watcherSelectedUser != null &&
            !data.any((u) => u.id == _watcherSelectedUser!.id)) {
          _watcherSelectedUser = data.isNotEmpty ? data.first : null;
          _updateDeepUserStream();
        }

        if (!_allUsersController.isClosed) {
          _allUsersController.add(data);
        }

        if (mounted) {
          setState(() {
            _streamEmissionsCount++;
          });
        }
      },
      onError: (err) {
        if (!_allUsersController.isClosed) {
          _allUsersController.addError(err);
        }
      },
    );
  }

  void _updateDeepUserStream() {
    // Cancel old subscription before starting a new one
    _deepUserSubscription?.cancel();
    _deepUserSubscription = null;

    if (_watcherSelectedUser != null) {
      _deepUserSubscription = Users.watchOne(
        _watcherSelectedUser!.id,
        include: [Includable.model<Post>()],
      ).listen(
        (data) {
          _deepUserCache = data;
          if (!_deepUserController.isClosed) {
            _deepUserController.add(data);
          }
        },
        onError: (err) {
          if (!_deepUserController.isClosed) {
            _deepUserController.addError(err);
          }
        },
      );
    } else {
      _deepUserCache = null;
      if (!_deepUserController.isClosed) {
        _deepUserController.add(null);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newPostTitleCtrl.dispose();
    _newPostContentCtrl.dispose();
    _deepUserSubscription?.cancel();
    _deepUserController.close();
    _activeUsersSubscription?.cancel();
    _activeUsersController.close();
    _allUsersSubscription?.cancel();
    _allUsersController.close();
    super.dispose();
  }

  // ==========================================
  // QUERY BUILDER SHOWCASE
  // ==========================================
  Future<void> _runQueryBuilder() async {
    setState(() {
      _isQueryRunning = true;
    });

    try {
      // Dynamic Query Builder Chaining!
      var query = Users.query;

      if (_selectedCity != null && _selectedCity != 'All') {
        query = query.where(Users.city.eq(_selectedCity!));
      }
      query = query.where(Users.age.gte(_selectedMinAge));
      if (_selectedGender != null && _selectedGender != 'All') {
        query = query.where(Users.gender.eq(_selectedGender!));
      }

      // Order and limit
      query = query.orderBy(Users.createdAt, descending: true).limit(10);

      // Extract SQL query to show in UI
      _generatedSql = query.toSql();

      // Execute query
      final results = await query.get();

      setState(() {
        _queryResults = results;
        _isQueryRunning = false;
      });
    } catch (e) {
      debugPrint('Query Builder error: $e');
      setState(() {
        _isQueryRunning = false;
      });
    }
  }

  // ==========================================
  // REACTIVE OPERATIONS
  // ==========================================
  Future<void> _toggleUserActive(User user) async {
    final updated = user.copyWith(isActive: !user.isActive);
    await Users.update(updated);
  }

  Future<void> _addPostToUser(User user) async {
    final title = _newPostTitleCtrl.text.trim();
    final content = _newPostContentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    final newPost = Post(
      id: const Uuid().v4(),
      title: title,
      content: content,
      userId: user.id,
    );

    await Posts.insert(newPost);

    _newPostTitleCtrl.clear();
    _newPostContentCtrl.clear();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post added successfully!', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF00C896),
        ),
      );
    }
  }

  // ==========================================
  // TRANSACTION BUFFERING OPERATIONS
  // ==========================================
  Future<void> _runMultipleInsertsOneByOne() async {
    setState(() => _isBufferingActionRunning = true);
    final uuid = const Uuid();

    for (var i = 1; i <= 3; i++) {
      final user = User(
        id: uuid.v4(),
        firstName: 'Individual',
        lastName: 'User $i',
        email: 'individual_user_${uuid.v4().substring(0, 5)}@sqflow.com',
        phone: '+359887111222',
        gender: 'Other',
        city: 'Sofia',
        country: 'Bulgaria',
        address: 'One-by-one road $i',
        isActive: true,
        password: 'pass',
      );
      await Users.insert(user);
      // Simulating a tiny delay so the streams have time to process and show multiple events
      await Future.delayed(const Duration(milliseconds: 50));
    }

    setState(() => _isBufferingActionRunning = false);
  }

  Future<void> _runMultipleInsertsInTransaction() async {
    setState(() => _isBufferingActionRunning = true);
    final uuid = const Uuid();

    await Users.transaction((txn) async {
      for (var i = 1; i <= 3; i++) {
        final user = User(
          id: uuid.v4(),
          firstName: 'Txn',
          lastName: 'User $i',
          email: 'txn_user_${uuid.v4().substring(0, 5)}@sqflow.com',
          phone: '+359887111222',
          gender: 'Other',
          city: 'Sofia',
          country: 'Bulgaria',
          address: 'Transaction square $i',
          isActive: true,
          password: 'pass',
        );
        await Users.insert(user, executor: txn);
      }
    });

    setState(() => _isBufferingActionRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          _buildAppBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildQueryBuilderTab(),
            _buildReactiveWatchersTab(),
            _buildTransactionBufferingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1A),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6C63FF),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(icon: Icon(Icons.psychology_outlined), text: 'Query Builder'),
          Tab(icon: Icon(Icons.settings_input_antenna), text: 'Watchers'),
          Tab(icon: Icon(Icons.layers_outlined), text: 'Buffering'),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reactive Playground',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white)),
            Text(
                'watchAll() · watchOne() · Query Chaining · Transaction Buffering',
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
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 64),
            child: Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.settings_input_antenna,
                  size: 64, color: Colors.white.withAlpha(38)),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: QUERY BUILDER PLAYGROUND
  // ==========================================
  Widget _buildQueryBuilderTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildSectionHeader('API Query Chaining Builder', Icons.code_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCityFilter(),
              const SizedBox(height: 16),
              _buildGenderFilter(),
              const SizedBox(height: 16),
              _buildMinAgeFilter(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSqlDisplayCard(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Query Results', Icons.format_list_bulleted),
            if (_isQueryRunning)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_queryResults.isEmpty)
          _buildEmptyResultsCard()
        else
          ..._queryResults.map((user) => _buildUserQueryCard(user)),
      ],
    );
  }

  Widget _buildCityFilter() {
    final cities = ['All', 'Sofia', 'Plovdiv', 'Varna'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FILTER BY CITY',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: cities.map((city) {
            final selected = (_selectedCity == null && city == 'All') ||
                (_selectedCity == city);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCity = city == 'All' ? null : city;
                  });
                  _runQueryBuilder();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF6C63FF).withAlpha(51)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withAlpha(26),
                    ),
                  ),
                  child: Center(
                    child: Text(city,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: selected ? Colors.white : Colors.white60,
                            fontWeight: selected ? FontWeight.bold : null)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderFilter() {
    final genders = ['All', 'M', 'F', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FILTER BY GENDER',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: genders.map((gender) {
            final selected = (_selectedGender == null && gender == 'All') ||
                (_selectedGender == gender);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = gender == 'All' ? null : gender;
                  });
                  _runQueryBuilder();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFC5C7D).withAlpha(51)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFC5C7D)
                          : Colors.white.withAlpha(26),
                    ),
                  ),
                  child: Center(
                    child: Text(gender,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: selected ? Colors.white : Colors.white60,
                            fontWeight: selected ? FontWeight.bold : null)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMinAgeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MINIMUM AGE FILTER',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold)),
            Text('Age >= $_selectedMinAge',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _selectedMinAge.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: const Color(0xFF6C63FF),
          inactiveColor: Colors.white.withAlpha(26),
          onChanged: (val) {
            setState(() {
              _selectedMinAge = val.toInt();
            });
            _runQueryBuilder();
          },
        ),
      ],
    );
  }

  Widget _buildSqlDisplayCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_ethernet,
                  size: 14, color: Color(0xFFFC5C7D)),
              const SizedBox(width: 6),
              Text('DYNAMICALLY COMPILED SQL',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: const Color(0xFFFC5C7D),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _generatedSql.isEmpty ? '-- Generating...' : _generatedSql,
            style:
                GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withAlpha(128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Center(
        child: Text(
          'No users match the dynamic query filters.\nTry relaxing the sliders or create users in the Validation tab.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white38, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildUserQueryCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF).withAlpha(38),
            radius: 18,
            child: Text(
              user.firstName[0] + user.lastName[0],
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                Text(
                  'City: ${user.city} · Age: ${user.age ?? "N/A"} · Gender: ${user.gender}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: REACTIVE WATCHERS SHOWCASE
  // ==========================================
  Widget _buildReactiveWatchersTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildSectionHeader(
            'Automated Reactive Streaming', Icons.wifi_tethering),
        const SizedBox(height: 8),
        Text(
          'SQFlow reacts to table updates sync automatically. Below, we watch users with where filters, and one specific user with deep relationships.',
          style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white54, height: 1.4),
        ),
        const SizedBox(height: 20),

        // ACTIVE USERS WATCHER CARD
        _buildActiveUsersWatcherCard(),
        const SizedBox(height: 24),

        // DEEP RELATIONSHIP WATCHER CARD
        _buildDeepUserWatcherCard(),
      ],
    );
  }

  Widget _buildActiveUsersWatcherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C896).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withAlpha(31),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('LIVE STREAM (watchAll)',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: const Color(0xFF00C896),
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('Users.isActive.eq(true)',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: Colors.white24)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Flipping the active switch updates the record in the DB, and the Stream updates instantly below with ZERO manually called notify functions.',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<User>>(
            stream: _activeUsersStream,
            initialData: _activeUsersCache,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return _buildEmptyState(
                    'No active users found. Activate some users below!');
              }

              return Column(
                children: users.map((user) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Switch(
                          value: user.isActive,
                          activeColor: const Color(0xFF00C896),
                          onChanged: (_) => _toggleUserActive(user),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeepUserWatcherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFC5C7D).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC5C7D).withAlpha(31),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('DEEP RELATIONSHIP WATCHER',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: const Color(0xFFFC5C7D),
                        fontWeight: FontWeight.bold)),
              ),
              Text('watchOne(..., include: [Post])',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: Colors.white24)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'We watch a user, but since we included the Post relationship, changing/inserting posts for this user triggers this Stream automatically!',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildWatcherUserSelector(),
          const SizedBox(height: 16),
          if (_watcherSelectedUser == null)
            _buildEmptyState('Select a user to activate the deep watcher')
          else
            StreamBuilder<User?>(
              stream: _deepUserController.stream,
              initialData: _deepUserCache,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = snapshot.data;
                if (user == null) {
                  return _buildEmptyState('User not found or deleted');
                }

                final posts = user.posts;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person,
                              color: const Color(0xFFFC5C7D), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _showAddPostDialog(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFC5C7D),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text('Add Post',
                                style: GoogleFonts.inter(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Posts (${posts.length}):',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white38)),
                    const SizedBox(height: 6),
                    if (posts.isEmpty)
                      _buildEmptyState(
                          'No posts. Add a post to see automatic stream refresh!')
                    else
                      ...posts.map((post) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.white.withAlpha(10)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.title,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(post.content,
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: Colors.white60)),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWatcherUserSelector() {
    return StreamBuilder<List<User>>(
      stream: _allUsersStream,
      initialData: _allUsersCache,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox();
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Text('Create some users in the first tab to use this',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11));
        }

        final hasSelectedUser = _watcherSelectedUser != null &&
            users.any((u) => u.id == _watcherSelectedUser!.id);
        final dropdownValue = hasSelectedUser ? _watcherSelectedUser!.id : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: dropdownValue,
              dropdownColor: const Color(0xFF0F0F1A),
              isExpanded: true,
              hint: Text('Select user to watch...',
                  style:
                      GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              items: users.map((user) {
                return DropdownMenuItem<String>(
                  value: user.id,
                  child: Text('${user.firstName} ${user.lastName}'),
                );
              }).toList(),
              onChanged: (userId) {
                if (userId != null) {
                  setState(() {
                    _watcherSelectedUser =
                        users.firstWhere((u) => u.id == userId);
                    _updateDeepUserStream();
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddPostDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text('Add New Post to User',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPostTitleCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Post Title',
                  hintText: 'e.g. Learning SQFlow ORM',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPostContentCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Post Content',
                  hintText: 'e.g. This is a reactive post!',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => _addPostToUser(user),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC5C7D)),
              child: Text('Insert', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 3: TRANSACTION BUFFERING SHOWCASE
  // ==========================================
  Widget _buildTransactionBufferingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildSectionHeader(
            'Stream Emission & Transaction Buffering', Icons.layers),
        const SizedBox(height: 8),
        Text(
          'During high-throughput writes (batching/looping inserts), triggering updates on every item leads to UI thrashing. SQFlow buffers notifications inside transactions, emitting only ONCE when the transaction commits.',
          style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white54, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildEmissionsCounterCard(),
        const SizedBox(height: 24),
        _buildBufferingActionButtons(),
      ],
    );
  }

  Widget _buildEmissionsCounterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(77)),
      ),
      child: Column(
        children: [
          Text('STREAM EMISSIONS COUNTER',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: const Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Text(
            '$_streamEmissionsCount',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Number of times active watchAll stream has emitted a new event',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _streamEmissionsCount = 0;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: BorderSide(color: Colors.white.withAlpha(31)),
            ),
            icon: const Icon(Icons.refresh, size: 14),
            label:
                Text('Reset Counter', style: GoogleFonts.inter(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBufferingActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPARE INSERT MODES (3 records)',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          // Action 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Individual Inserts',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                        'Inserts 3 users using separate write calls. Emits 3 times.',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isBufferingActionRunning
                    ? null
                    : _runMultipleInsertsOneByOne,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC5C7D),
                ),
                child: Text('Run', style: GoogleFonts.inter()),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white12),
          ),

          // Action 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inside Single Transaction',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                        'Inserts 3 users wrapped in Users.transaction(). Emits only ONCE upon commit.',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isBufferingActionRunning
                    ? null
                    : _runMultipleInsertsInTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                ),
                child: Text('Run Txn', style: GoogleFonts.inter()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GENERAL WIDGETS
  // ==========================================
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
        ),
      ),
    );
  }
}
