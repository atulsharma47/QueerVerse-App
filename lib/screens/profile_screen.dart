import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/feed/feed_app_bar.dart';
import 'admin_reports_screen.dart';
import 'admin_premium_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _glowController;
  bool isSendingVerification = false;

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

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => isSendingVerification = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent — check your inbox'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => isSendingVerification = false);
    }
  }

  Future<void> _refreshVerification(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed != null) {
      await UserService.syncEmailVerified(uid, refreshed.emailVerified);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          refreshed?.emailVerified == true
              ? 'Email verified!'
              : 'Not verified yet',
        ),
      ),
    );
  }

  Animation<double> _staggerFade(int index, int total) {
    final start = (index / total) * 0.6;
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(backgroundColor: FC.bg, body: SizedBox());
    }

    return Scaffold(
      backgroundColor: FC.bg,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: UserService.userStream(currentUser.uid),
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
                  'Profile not found',
                  style: TextStyle(color: FC.textMid),
                ),
              );
            }

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
              if (!user.isEmailVerified) _buildEmailVerificationBanner(user),
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
              _buildPhotoGrid(context, user),
              _buildDetailRow('Identity', Icons.person_outline, identity),
              _buildDetailRow(
                'Lifestyle',
                Icons.local_cafe_outlined,
                lifestyle,
              ),
              _buildDetailRow(
                'Relationship',
                Icons.favorite_border,
                user.relationshipStatus,
              ),
              _buildDetailRow(
                'Pride',
                Icons.diversity_3_outlined,
                user.prideStatus,
              ),
              _buildVerificationRow(user),
              _buildCompletionBar(user),
              if (user.isAdmin) _buildAdminButtons(context),
              _buildLogoutButton(context),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmailVerificationBanner(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: Colors.amber),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Verify your email to unlock the verified badge',
              style: TextStyle(color: FC.textHi, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: isSendingVerification ? null : _sendVerificationEmail,
            child: const Text(
              'Send',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _refreshVerification(user.uid),
            child: const Text(
              'Refresh',
              style: TextStyle(color: FC.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

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
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: FC.primary.withValues(alpha: glow),
                        blurRadius: 24,
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
                  radius: 60,
                  backgroundColor: FC.card,
                  backgroundImage: user.profileImage.isNotEmpty
                      ? NetworkImage(user.profileImage)
                      : null,
                  child: user.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 56, color: FC.textLo)
                      : null,
                ),
              ),
            ),
            if (user.isOnline)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
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
            if (user.isEmailVerified ||
                user.isPhotoVerified ||
                user.isIdVerified) ...[
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
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
          child: Container(
            width: 220,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [FC.primary, FC.accent]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: FC.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
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
        user.bio.isNotEmpty
            ? user.bio
            : 'Tell people about yourself — tap Edit Profile to add a bio.',
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

  Widget _buildPhotoGrid(BuildContext context, UserModel user) {
    final photos = user.photos;
    return _sectionCard(
      title: 'My Photos',
      icon: Icons.photo_library_outlined,
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            if (index == photos.length) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FC.border.withValues(alpha: 0.7)),
                    color: FC.bg,
                  ),
                  child: const Icon(Icons.add, color: FC.textLo),
                ),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                photos[index],
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            );
          },
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
              value.isNotEmpty ? value : 'Not set',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: value.isNotEmpty ? FC.textMid : FC.textLo,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: FC.textLo),
        ],
      ),
    );
  }

  Widget _buildVerificationRow(UserModel user) {
    return _sectionCard(
      title: 'Verification',
      icon: Icons.verified_user_outlined,
      child: Row(
        children: [
          _verificationBadge(
            'Email',
            Icons.email_outlined,
            user.isEmailVerified,
          ),
          const SizedBox(width: 10),
          _verificationBadge(
            'Photo',
            Icons.image_outlined,
            user.isPhotoVerified,
          ),
          const SizedBox(width: 10),
          _verificationBadge('ID', Icons.badge_outlined, user.isIdVerified),
        ],
      ),
    );
  }

  Widget _verificationBadge(String label, IconData icon, bool verified) {
    final color = verified ? Colors.greenAccent.shade400 : FC.textLo;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: FC.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(verified ? Icons.check_circle : icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBar(UserModel user) {
    final pct = user.profileCompletion;
    return _sectionCard(
      title: 'Profile Strength',
      icon: Icons.bolt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: FC.bg,
              valueColor: const AlwaysStoppedAnimation(FC.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).round()}% complete',
            style: const TextStyle(color: FC.textLo, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminButtons(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
          ),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPremiumScreen()),
          ),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF7B733).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF7B733).withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond, color: Color(0xFFF7B733)),
                SizedBox(width: 8),
                Text(
                  'Manage Premium',
                  style: TextStyle(
                    color: Color(0xFFF7B733),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _logout(context),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
