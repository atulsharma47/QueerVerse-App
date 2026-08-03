import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../screens/user_profile_screen.dart';
import '../../screens/chat_room_screen.dart';
import '../feed/feed_app_bar.dart'; // FC color tokens

/// Grid card used on the Search Users screen — photo, presence dot,
/// verified badge, name/pronouns/orientation, interest chips, and
/// like + chat quick actions. Tap anywhere on the photo/name area to
/// open the full profile.
class UserSearchCard extends StatelessWidget {
  final UserModel user;

  const UserSearchCard({super.key, required this.user});

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = currentUid != null && user.likedBy.contains(currentUid);

    return Container(
      decoration: BoxDecoration(
        color: FC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FC.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: FC.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ──
          GestureDetector(
            onTap: () => _openProfile(context),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  user.profileImage.isNotEmpty
                      ? Image.network(
                          user.profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        )
                      : _avatarFallback(),

                  // Bottom gradient so the location badge stays legible.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Location badge, top-left.
                  if (user.location.isNotEmpty)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _Pill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 90),
                              child: Text(
                                user.location,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Online dot, top-right.
                  if (user.isOnline)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: FC.online,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),

                  // Premium crown, bottom-right (if applicable).
                  if (user.isPremium)
                    const Positioned(
                      right: 8,
                      bottom: 8,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFFC857),
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(context),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FC.textHi,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: FC.primary, size: 14),
                      ],
                    ],
                  ),
                ),
                if (user.pronouns.isNotEmpty || user.orientation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        user.pronouns,
                        user.orientation,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FC.textLo, fontSize: 11.5),
                    ),
                  ),

                if (user.interests.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...user.interests
                          .take(2)
                          .map((i) => _InterestTag(label: i)),
                      if (user.interests.length > 2)
                        _InterestTag(label: '+${user.interests.length - 2}'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // ── Actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? FC.accent : FC.textMid,
                    onTap: currentUid == null
                        ? null
                        : () =>
                              UserService.toggleLikeUser(currentUid, user.uid),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: FC.textMid,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          userId: user.uid,
                          userName: user.name,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [FC.primary, FC.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _InterestTag extends StatelessWidget {
  final String label;
  const _InterestTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: FC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FC.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: FC.textMid,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FC.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
