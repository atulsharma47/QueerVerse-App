import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

// Colour tokens shared across the feed
class FC {
  static const bg = Color(0xFF0A0A12);
  static const surface = Color(0xFF13131F);
  static const card = Color(0xFF16161F);
  static const border = Color(0xFF2A2A3A);
  static const primary = Color(0xFF8B5CF6);
  static const accent = Color(0xFFEC4899);
  static const online = Color(0xFF22C55E);
  static const textHi = Colors.white;
  static const textMid = Color(0xFFB0B0C8);
  static const textLo = Color(0xFF6B6B85);
}

class FeedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final VoidCallback onChatTap;
  final VoidCallback onNotificationTap;

  const FeedAppBar({
    super.key,
    required this.onMenuTap,
    required this.onSearchTap,
    required this.onChatTap,
    required this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FC.surface,
        border: Border(bottom: BorderSide(color: FC.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // ── Menu / avatar ──
              GestureDetector(
                onTap: onMenuTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [FC.primary, FC.accent]),
                  ),
                  child: const Icon(Icons.menu, color: Colors.white, size: 18),
                ),
              ),

              // ── Logo ──
              const Expanded(
                child: Center(
                  child: Text(
                    'QUEERVERSE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              // ── Search ──
              _NavIcon(icon: Icons.search, onTap: onSearchTap),
              const SizedBox(width: 6),

              // ── Chat (live badge) ──
              StreamBuilder<int>(
                stream: NotificationService.unreadChatCount(),
                builder: (_, snap) => _NavIcon(
                  icon: Icons.chat_bubble_outline,
                  badge: snap.data ?? 0,
                  onTap: onChatTap,
                ),
              ),
              const SizedBox(width: 6),

              // ── Notifications (live badge) ──
              StreamBuilder<int>(
                stream: NotificationService.unreadCount(),
                builder: (_, snap) => _NavIcon(
                  icon: Icons.notifications_none,
                  badge: snap.data ?? 0,
                  onTap: onNotificationTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _NavIcon({required this.icon, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: FC.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
