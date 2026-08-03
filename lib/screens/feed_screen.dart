import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import '../services/notification_service.dart';

import '../widgets/feed/feed_app_bar.dart';
import '../widgets/feed/story_section.dart';
import '../widgets/feed/feed_filter_chips.dart';
import '../widgets/feed/post_card.dart';
import '../widgets/feed/glass_bottom_navigation.dart';
import '../widgets/feed/empty_feed.dart';
import '../widgets/feed/mood_bottom_sheet.dart';

// Existing screens (already in your project – don't recreate)
// These are siblings of feed_screen.dart inside lib/screens/, so no prefix needed
import 'search_users_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'events_screen.dart';
import 'anonymous_screen.dart';
import 'saved_posts_screen.dart';
import 'settings_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  // ── Animated cosmic background ─────────────
  Widget _background() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) {
        final t = _bgCtrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                -0.6 + 0.4 * math.sin(t * math.pi * 2),
                -0.8 + 0.3 * math.cos(t * math.pi * 2),
              ),
              radius: 1.4,
              colors: const [
                Color(0xFF1A0A2E),
                Color(0xFF0A0A12),
                Color(0xFF050510),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ── Greeting bar ────────────────────────────
  Widget _greeting(String name, String mood, String moodEmoji) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Good evening, $name! 🌈',
              style: const TextStyle(color: Color(0xFFB0B0C8), fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => MoodBottomSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2A2A3A)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    moodEmoji.isNotEmpty ? moodEmoji : '😊',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    mood.isNotEmpty ? mood : 'Set Mood',
                    style: const TextStyle(
                      color: Color(0xFFB0B0C8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer (menu button) ────────────────────
  void _openDrawer(BuildContext ctx) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx2, anim, __, ___) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: _AppDrawer(animation: anim),
        );
      },
    );
  }

  // ── Bottom nav handler ──────────────────────
  void _onNavTap(int i) {
    if (i == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );
      return;
    }
    setState(() => _navIndex = i);
  }

  // ── Body by nav index ───────────────────────
  Widget _body() {
    switch (_navIndex) {
      case 1:
        return const SearchUsersScreen();
      case 3:
        return const ChatScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _feedBody();
    }
  }

  Widget _feedBody() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ChangeNotifierProvider(
      create: (_) => FeedProvider(),
      child: Column(
        children: [
          // Greeting (live from Firestore)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (_, snap) {
              final data = snap.data?.data() as Map<String, dynamic>? ?? {};
              final name = data['name'] as String? ?? 'there';
              final mood = data['mood'] as String? ?? '';
              final moodEmoji = data['moodEmoji'] as String? ?? '';
              return _greeting(name, mood, moodEmoji);
            },
          ),

          const SizedBox(height: 10),
          const StorySection(),
          const SizedBox(height: 10),
          const FeedFilterChips(),
          const SizedBox(height: 10),

          // Post list
          Expanded(
            child: Consumer<FeedProvider>(
              builder: (_, provider, __) {
                return StreamBuilder<List<PostModel>>(
                  stream: provider.postsStream,
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return const Center(
                        child: Text(
                          'Something went wrong',
                          style: TextStyle(color: Color(0xFFB0B0C8)),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                        ),
                      );
                    }
                    final posts = snap.data!;
                    if (posts.isEmpty) return const EmptyFeed();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: posts.length,
                      itemBuilder: (_, i) =>
                          PostCard(post: posts[i], currentUserId: uid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),

      // ── Single app bar – no duplicate ──
      appBar: FeedAppBar(
        onMenuTap: () => _openDrawer(context),
        onSearchTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
        ),
        onChatTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        onNotificationTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(child: _background()),
          SafeArea(child: _body()),
        ],
      ),

      // ── Single bottom nav ──
      bottomNavigationBar: StreamBuilder<int>(
        stream: NotificationService.unreadChatCount(),
        builder: (_, snap) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: GlassBottomNavigation(
            selectedIndex: _navIndex,
            onTap: _onNavTap,
            chatBadge: snap.data ?? 0,
          ),
        ),
      ),
    );
  }
}

// ── Side drawer ──────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final Animation<double> animation;
  const _AppDrawer({required this.animation});

  @override
  Widget build(BuildContext context) {
    const items = [
      {'icon': Icons.person_outline, 'label': 'Profile'},
      {'icon': Icons.bookmark_border, 'label': 'Saved Posts'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
      {'icon': Icons.event_outlined, 'label': 'Events'},
      {'icon': Icons.masks_outlined, 'label': 'Anonymous'},
      {'icon': Icons.logout, 'label': 'Logout', 'red': true},
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.72,
          height: double.infinity,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Color(0xFF2A2A3A))),
          ),
          child: Material(
            color: const Color(0xFF13131F),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QueerVerse',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Your safe space 🌈',
                              style: TextStyle(
                                color: Color(0xFFB0B0C8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF2A2A3A)),

                  // Menu items
                  ...items.map((item) {
                    final isRed = item['red'] == true;
                    return ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isRed
                            ? Colors.redAccent
                            : const Color(0xFFB0B0C8),
                      ),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isRed ? Colors.redAccent : Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () {
                        final label = item['label'] as String;
                        Navigator.pop(context);

                        switch (label) {
                          case 'Profile':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                            break;
                          case 'Saved Posts':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavedPostsScreen(),
                              ),
                            );
                            break;
                          case 'Settings':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                            break;
                          case 'Events':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EventsScreen(),
                              ),
                            );
                            break;
                          case 'Anonymous':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnonymousScreen(),
                              ),
                            );
                            break;
                          case 'Logout':
                            FirebaseAuth.instance.signOut();
                            break;
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
