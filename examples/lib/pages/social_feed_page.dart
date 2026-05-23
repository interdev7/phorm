import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflow/sqflow.dart' hide Column;
import 'package:sqflow_example/models/post.dart';
import 'package:sqflow_example/models/user.dart';
import 'package:uuid/uuid.dart';

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isSeeding = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    // Demonstrates: eager loading via include (HasMany / BelongsTo)
    final result = await Posts.readAll(include: [Includable.model<User>()]);
    setState(() {
      _posts = result.data;
      _isLoading = false;
    });
  }

  /// Demonstrates: SqflowCore.transaction() — all-or-nothing atomic write
  Future<void> _seedWithTransaction() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = null;
    });

    final uuid = const Uuid();
    final userId = uuid.v4();

    final firstNames = ['John', 'Alice', 'Michael', 'Emma', 'David', 'Sophia', 'Robert', 'Olivia', 'William', 'Isabella'];
    final lastNames = ['Doe', 'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez'];
    final random = Random();
    final firstName = firstNames[random.nextInt(firstNames.length)];
    final lastName = lastNames[random.nextInt(lastNames.length)];

    try {
      await Posts.transaction((txn) async {
        // Step 1: Create author inside the transaction
        final author = User(
          id: userId,
          firstName: firstName,
          lastName: lastName,
          email: '${uuid.v4().substring(0, 6)}@seed.com',
          phone: '+359887001122',
          birthDate: '1985-03-15',
          city: 'Plovdiv',
          country: 'Bulgaria',
          address: '45 Rose Valley',
          gender: random.nextBool() ? 'M' : 'F',
          password: 'secret_password_123',
        );
        await Users.insert(author, executor: txn);

        // Step 2: Create posts linked to the author inside same transaction
        final titles = [
          'Getting started with Sqflow ORM',
          'How to use Relationships (HasMany, BelongsTo)',
          'Transactions, Reactivity & Paranoid explained',
        ];
        for (final title in titles) {
          final id = uuid.v4();
          await Posts.insert(
            Post(
              id: id,
              title: title,
              content:
                  'This post was created atomically together with its author inside a single transaction.',
              userId: userId,
            ),
            executor: txn,
          );
        }
      });

      setState(() => _statusMessage =
          '✅ Transaction committed! Author + 3 posts created atomically.');
      await _loadPosts();
    } catch (e) {
      setState(() => _statusMessage = '❌ Transaction rolled back:\n$e');
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  Future<void> _deletePost(String id) async {
    await Posts.delete(id);
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTransactionCard(),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildStatusBanner(),
                ],
                const SizedBox(height: 20),
                _buildFeedHeader(),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator()))
                else if (_posts.isEmpty)
                  _buildEmptyState()
                else
                  ..._posts.map(_buildPostCard),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1A),
      actions: [
        IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPosts),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social Feed',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white)),
            Text('HasMany · BelongsTo · include · transaction()',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.dynamic_feed,
                  size: 64, color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF11998E).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF11998E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('ATOMIC TRANSACTION',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: const Color(0xFF38EF7D),
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            'Creates one Author + 3 Posts atomically. If any step fails, all changes are rolled back — no partial data.',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSeeding ? null : _seedWithTransaction,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11998E)),
              icon: _isSeeding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bolt_rounded),
              label:
                  Text(_isSeeding ? 'Committing...' : 'Seed via Transaction'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isOk = _statusMessage!.startsWith('✅');
    final color = isOk ? const Color(0xFF38EF7D) : const Color(0xFFFF6B6B);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(_statusMessage!,
          style: GoogleFonts.inter(fontSize: 12, color: color, height: 1.4)),
    );
  }

  Widget _buildFeedHeader() {
    return Row(
      children: [
        Text('Posts Feed',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF11998E).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_posts.length}',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF38EF7D),
                  fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        Text('include: [Includable.model<User>()]',
            style:
                GoogleFonts.jetBrainsMono(fontSize: 9, color: Colors.white24)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.feed_outlined,
                size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('No posts yet.',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Tap "Seed via Transaction" to add data.',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final author = post.user;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (author != null)
            Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF11998E).withOpacity(0.25),
                child: Text(
                  '${author.firstName[0]}${author.lastName[0]}',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38EF7D)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${author.firstName} ${author.lastName}',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white)),
                    Text(author.email,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFFF6B6B)),
                onPressed: () => _deletePost(post.id),
              ),
            ]),
          const SizedBox(height: 12),
          Text(post.title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(post.content,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white54, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Column(
            spacing: 3,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metaTag('Post #${post.id}', const Color(0xFF4FACFE)),
              const SizedBox(width: 8),
              _metaTag('user_id: ${post.userId}', const Color(0xFF11998E)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color)),
    );
  }
}
