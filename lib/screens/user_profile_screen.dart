import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/feed/feed_app_bar.dart';
import '../widgets/user_posts_section.dart';
import 'chat_room_screen.dart';
import 'follow_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Animation<double> _staggerFade(int index, int total) {
    final start = (index / total) * 0.6;
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  // ---------- Backend actions (unchanged logic from before) ----------

  Future<void> blockUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);
    final targetUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);

    await FirebaseFirestore.instance.collection('blocked_users').add({
      'blockerId': currentUser.uid,
      'blockedId': widget.userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await currentUserRef.update({
      'following': FieldValue.arrayRemove([widget.userId]),
    });
    await targetUserRef.update({
      'followers': FieldValue.arrayRemove([currentUser.uid]),
    });
    await currentUserRef.update({
      'followers': FieldValue.arrayRemove([widget.userId]),
    });
    await targetUserRef.update({
      'following': FieldValue.arrayRemove([currentUser.uid]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked and unfollowed')),
    );
    Navigator.pop(context);
  }

  Future<void> toggleFollow(String targetUserId, bool isFollowing) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);
    final targetUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);

    if (isFollowing) {
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });
      await targetUserRef.update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([targetUserId]),
      });
      await targetUserRef.update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final senderName = currentUserDoc.data()?['name'] ?? 'User';

      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': targetUserId,
        'senderName': senderName,
        'type': 'follow',
        'message': '$senderName started following you',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: FC.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: FC.bg,
        foregroundColor: FC.textHi,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: UserService.userStream(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: FC.primary),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(
              child: Text(
                'User not found',
                style: TextStyle(color: FC.textMid),
              ),
            );
          }

          final isFollowing = user.followers.contains(currentUserId);
          final isOwnProfile = currentUserId == widget.userId;

          final identity = [
            user.gender,
            user.orientation,
            user.pronouns,
          ].where((s) => s.isNotEmpty).join(' • ');
          final lifestyle = [
            user.smokingStatus,
            user.drinkingStatus,
          ].where((s) => s.isNotEmpty).join(' • ');

          final items = <Widget>[
            _buildHeader(context, user),
            _buildFollowStats(context, user),
            if (!isOwnProfile) _buildActionButtons(context, user, isFollowing),
            _buildAboutMe(user),
            if (user.lookingFor.isNotEmpty)
              _buildChipSection(
                title: 'Looking For',
                icon: Icons.favorite,
                tags: user.lookingFor,
              ),
            if (user.interests.isNotEmpty)
              _buildChipSection(
                title: 'Interests',
                icon: Icons.star_outline,
                tags: user.interests,
              ),
            if (user.photos.isNotEmpty) _buildPhotoGrid(user),
            if (identity.isNotEmpty)
              _buildDetailRow('Identity', Icons.person_outline, identity),
            if (lifestyle.isNotEmpty)
              _buildDetailRow(
                'Lifestyle',
                Icons.local_cafe_outlined,
                lifestyle,
              ),
            if (user.relationshipStatus.isNotEmpty)
              _buildDetailRow(
                'Relationship',
                Icons.favorite_border,
                user.relationshipStatus,
              ),
            if (user.prideStatus.isNotEmpty)
              _buildDetailRow(
                'Pride',
                Icons.diversity_3_outlined,
                user.prideStatus,
              ),
            _buildPostsHeader(),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FadeTransition(
                          opacity: _staggerFade(i, items.length),
                          child: SlideTransition(
                            position: _staggerFade(i, items.length).drive(
                              Tween(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ),
                            ),
                            child: items[i],
                          ),
                        ),
                      ),
                    UserPostsSection(userId: widget.userId),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Header ----------

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = 0.22 + (_glowController.value * 0.14);
                return Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: FC.primary.withValues(alpha: glow),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [FC.primary, FC.accent]),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: FC.card,
                  backgroundImage: user.profileImage.isNotEmpty
                      ? NetworkImage(user.profileImage)
                      : null,
                  child: user.profileImage.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            if (user.isOnline)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.shade400,
                    border: Border.all(color: FC.bg, width: 3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (user.isPremium)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF7B733), Color(0xFFFFD98E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond, size: 14, color: Colors.black87),
                SizedBox(width: 5),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.name,
              style: const TextStyle(
                color: FC.textHi,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (user.isPhotoVerified || user.isIdVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: FC.primary, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            if (user.orientation.isNotEmpty) _pill(user.orientation),
            if (user.pronouns.isNotEmpty) _pill(user.pronouns),
            if (user.location.isNotEmpty) _pill(user.location),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: FC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FC.border.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: FC.textMid, fontSize: 12),
      ),
    );
  }

  // ---------- Followers / Following ----------

  Widget _buildFollowStats(BuildContext context, UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FollowListScreen(title: 'Followers', userIds: user.followers),
            ),
          ),
          child: _statColumn(user.followers.length.toString(), 'Followers'),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FollowListScreen(title: 'Following', userIds: user.following),
            ),
          ),
          child: _statColumn(user.following.length.toString(), 'Following'),
        ),
      ],
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: FC.textHi,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: FC.textLo, fontSize: 12)),
      ],
    );
  }

  // ---------- Follow / Block / Message ----------

  Widget _buildActionButtons(
    BuildContext context,
    UserModel user,
    bool isFollowing,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: GestureDetector(
            onTap: () async {
              final currentUserId = FirebaseAuth.instance.currentUser!.uid;

              final blockedByThem = await FirebaseFirestore.instance
                  .collection('blocked_users')
                  .where('blockerId', isEqualTo: widget.userId)
                  .where('blockedId', isEqualTo: currentUserId)
                  .get();
              final blockedByMe = await FirebaseFirestore.instance
                  .collection('blocked_users')
                  .where('blockerId', isEqualTo: currentUserId)
                  .where('blockedId', isEqualTo: widget.userId)
                  .get();

              if (blockedByThem.docs.isNotEmpty ||
                  blockedByMe.docs.isNotEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You cannot follow a blocked user'),
                  ),
                );
                return;
              }

              await toggleFollow(widget.userId, isFollowing);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: isFollowing
                    ? null
                    : const LinearGradient(colors: [FC.primary, FC.accent]),
                color: isFollowing ? FC.card : null,
                borderRadius: BorderRadius.circular(16),
                border: isFollowing
                    ? Border.all(color: FC.border.withValues(alpha: 0.6))
                    : null,
              ),
              child: Center(
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: isFollowing ? FC.textHi : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: GestureDetector(
            onTap: () async {
              final currentUserId = FirebaseAuth.instance.currentUser!.uid;

              final blocked = await FirebaseFirestore.instance
                  .collection('blocked_users')
                  .where('blockerId', isEqualTo: widget.userId)
                  .where('blockedId', isEqualTo: currentUserId)
                  .get();

              if (blocked.docs.isNotEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You cannot message this user')),
                );
                return;
              }

              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    userId: widget.userId,
                    userName: user.name,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: FC.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FC.border.withValues(alpha: 0.6)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 18, color: FC.textHi),
                  SizedBox(width: 8),
                  Text(
                    'Message',
                    style: TextStyle(
                      color: FC.textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: GestureDetector(
            onTap: blockUser,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Block User',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Reusable card shell ----------

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FC.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: FC.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: FC.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildAboutMe(UserModel user) {
    return _sectionCard(
      title: 'About Me',
      icon: Icons.format_quote,
      child: Text(
        user.bio.isNotEmpty ? user.bio : 'No bio added yet',
        style: TextStyle(
          color: user.bio.isNotEmpty ? FC.textHi : FC.textLo,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildChipSection({
    required String title,
    required IconData icon,
    required List<String> tags,
  }) {
    return _sectionCard(
      title: title,
      icon: icon,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => _chip(tag)).toList(),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: FC.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FC.border.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: FC.textHi,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(UserModel user) {
    return _sectionCard(
      title: 'Photos',
      icon: Icons.photo_library_outlined,
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: user.photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              user.photos[index],
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FC.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: FC.textMid),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: FC.textHi,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: FC.textMid, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Posts',
        style: TextStyle(
          color: FC.primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
