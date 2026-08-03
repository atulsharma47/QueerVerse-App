import 'package:flutter/material.dart';
import 'feed_app_bar.dart';

class GlassBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int chatBadge;

  const GlassBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.chatBadge = 0,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.search_rounded, 'label': 'Search'},
      {'icon': Icons.add_box_rounded, 'label': 'Create'}, // centre FAB
      {'icon': Icons.chat_bubble_rounded, 'label': 'Chat'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: FC.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: FC.border),
        boxShadow: [
          BoxShadow(
            color: FC.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isCreate = i == 2;
          final isSelected = selectedIndex == i;

          if (isCreate) {
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [FC.primary, FC.accent]),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            );
          }

          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: isSelected ? FC.primary : FC.textLo,
                      size: 24,
                    ),
                    if (i == 3 && chatBadge > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: FC.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              chatBadge.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  items[i]['label'] as String,
                  style: TextStyle(
                    color: isSelected ? FC.primary : FC.textLo,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
