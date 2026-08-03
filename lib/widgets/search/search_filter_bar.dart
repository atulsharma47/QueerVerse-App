import 'package:flutter/material.dart';
import '../feed/feed_app_bar.dart'; // FC color tokens

enum SortOption { recentlyActive, nameAZ }

/// Mutable filter state for the search screen. Kept as a plain class
/// (not a provider) since it only needs to live for this screen.
class SearchFilters {
  bool onlineOnly = false;
  bool verifiedOnly = false;
  String? gender;
  String? orientation;
  final Set<String> lookingFor = {};
  SortOption sort = SortOption.recentlyActive;

  bool get isDefault =>
      !onlineOnly &&
      !verifiedOnly &&
      gender == null &&
      orientation == null &&
      lookingFor.isEmpty;

  void reset() {
    onlineOnly = false;
    verifiedOnly = false;
    gender = null;
    orientation = null;
    lookingFor.clear();
  }
}

const kLookingForOptions = [
  'Dating',
  'Meetups',
  'Friends',
  'Long Term',
  'Casual',
  'Networking',
];

/// Horizontal row of filter chips. [availableGenders] / [availableOrientations]
/// are built live from whatever values users have actually entered, since
/// gender/orientation are free-text fields in UserModel.
class SearchFilterBar extends StatelessWidget {
  final SearchFilters filters;
  final List<String> availableGenders;
  final List<String> availableOrientations;
  final VoidCallback onChanged;

  const SearchFilterBar({
    super.key,
    required this.filters,
    required this.availableGenders,
    required this.availableOrientations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ToggleChip(
            label: 'Online',
            icon: Icons.circle,
            iconColor: FC.online,
            selected: filters.onlineOnly,
            onTap: () {
              filters.onlineOnly = !filters.onlineOnly;
              onChanged();
            },
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Verified',
            icon: Icons.verified,
            iconColor: FC.primary,
            selected: filters.verifiedOnly,
            onTap: () {
              filters.verifiedOnly = !filters.verifiedOnly;
              onChanged();
            },
          ),
          const SizedBox(width: 8),
          _DropdownChip(
            label: filters.gender ?? 'Gender',
            selected: filters.gender != null,
            options: availableGenders,
            onSelected: (v) {
              filters.gender = v;
              onChanged();
            },
          ),
          const SizedBox(width: 8),
          _DropdownChip(
            label: filters.orientation ?? 'Orientation',
            selected: filters.orientation != null,
            options: availableOrientations,
            onSelected: (v) {
              filters.orientation = v;
              onChanged();
            },
          ),
          const SizedBox(width: 8),
          _MultiDropdownChip(
            label: filters.lookingFor.isEmpty
                ? 'Looking For'
                : filters.lookingFor.join(', '),
            selected: filters.lookingFor.isNotEmpty,
            options: kLookingForOptions,
            selectedOptions: filters.lookingFor,
            onChanged: onChanged,
          ),
          if (!filters.isDefault) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                filters.reset();
                onChanged();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, color: FC.accent, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          color: FC.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? iconColor.withValues(alpha: 0.16) : FC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? iconColor : FC.border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 9, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : FC.textMid,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String label;
  final bool selected;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  const _DropdownChip({
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      color: FC.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: FC.border),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Any')),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? FC.primary.withValues(alpha: 0.16) : FC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? FC.primary : FC.border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 90),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : FC.textMid,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: selected ? Colors.white : FC.textMid,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiDropdownChip extends StatelessWidget {
  final String label;
  final bool selected;
  final List<String> options;
  final Set<String> selectedOptions;
  final VoidCallback onChanged;

  const _MultiDropdownChip({
    required this.label,
    required this.selected,
    required this.options,
    required this.selectedOptions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          backgroundColor: FC.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Looking For',
                        style: TextStyle(
                          color: FC.textHi,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: options.map((o) {
                          final isSel = selectedOptions.contains(o);
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                isSel
                                    ? selectedOptions.remove(o)
                                    : selectedOptions.add(o);
                              });
                              onChanged();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? FC.primary.withValues(alpha: 0.2)
                                    : FC.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel ? FC.primary : FC.border,
                                ),
                              ),
                              child: Text(
                                o,
                                style: TextStyle(
                                  color: isSel ? Colors.white : FC.textMid,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? FC.primary.withValues(alpha: 0.16) : FC.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? FC.primary : FC.border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : FC.textMid,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: selected ? Colors.white : FC.textMid,
            ),
          ],
        ),
      ),
    );
  }
}
