import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import 'feed_app_bar.dart';

class FeedFilterChips extends StatelessWidget {
  const FeedFilterChips({super.key});

  static const _labels = {
    FeedFilter.all: 'All',
    FeedFilter.friends: 'Friends',
    FeedFilter.nearby: 'Nearby',
    FeedFilter.trending: 'Trending',
    FeedFilter.following: 'Following',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: FeedFilter.values.map((f) {
          final selected = provider.filter == f;
          return GestureDetector(
            onTap: () => provider.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [FC.primary, FC.accent])
                    : null,
                color: selected ? null : FC.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.transparent : FC.border,
                ),
              ),
              child: Text(
                _labels[f]!,
                style: TextStyle(
                  color: selected ? Colors.white : FC.textMid,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
