import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/feed/feed_app_bar.dart'; // FC color tokens
import '../widgets/search/search_filter_bar.dart';
import '../widgets/search/user_search_card.dart';
import '../widgets/search/user_search_tile.dart';

enum _ViewMode { grid, list }

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _ViewMode _viewMode = _ViewMode.grid;
  final _filters = SearchFilters();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _applyFiltersAndSort(List<UserModel> users) {
    var result = users.where((u) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchesName = u.name.toLowerCase().contains(q);
        final matchesInterest = u.interests.any(
          (i) => i.toLowerCase().contains(q),
        );
        if (!matchesName && !matchesInterest) return false;
      }
      if (_filters.onlineOnly && !u.isOnline) return false;
      if (_filters.verifiedOnly && !u.isVerified) return false;
      if (_filters.gender != null && u.gender != _filters.gender) {
        return false;
      }
      if (_filters.orientation != null &&
          u.orientation != _filters.orientation) {
        return false;
      }
      if (_filters.lookingFor.isNotEmpty &&
          !_filters.lookingFor.any((lf) => u.lookingFor.contains(lf))) {
        return false;
      }
      return true;
    }).toList();

    switch (_filters.sort) {
      case SortOption.recentlyActive:
        result.sort((a, b) {
          final aTime = a.lastSeen?.millisecondsSinceEpoch ?? 0;
          final bTime = b.lastSeen?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });
        break;
      case SortOption.nameAZ:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: FC.bg,
      appBar: AppBar(
        backgroundColor: FC.surface,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Search Users',
          style: TextStyle(fontWeight: FontWeight.w800, color: FC.accent),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: UserService.searchableUsersStream(currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: FC.primary),
            );
          }

          final allUsers = snapshot.data!;
          final genders =
              allUsers
                  .map((u) => u.gender)
                  .where((g) => g.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final orientations =
              allUsers
                  .map((u) => u.orientation)
                  .where((o) => o.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          final results = _applyFiltersAndSort(allUsers);

          return Column(
            children: [
              // ── Search field ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or interest...',
                    hintStyle: const TextStyle(color: FC.textLo),
                    prefixIcon: const Icon(Icons.search, color: FC.accent),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear, color: FC.textLo),
                          )
                        : null,
                    filled: true,
                    fillColor: FC.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: FC.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: FC.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: FC.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),

              // ── Filters ──
              SearchFilterBar(
                filters: _filters,
                availableGenders: genders,
                availableOrientations: orientations,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 10),

              // ── Result count + sort + view toggle ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${results.length} user${results.length == 1 ? '' : 's'} found',
                      style: const TextStyle(
                        color: FC.textMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<SortOption>(
                      color: FC.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: FC.border),
                      ),
                      onSelected: (v) => setState(() => _filters.sort = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: SortOption.recentlyActive,
                          child: Text('Recently Active'),
                        ),
                        PopupMenuItem(
                          value: SortOption.nameAZ,
                          child: Text('Name A-Z'),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sort: ${_filters.sort == SortOption.recentlyActive ? 'Recently Active' : 'Name A-Z'}',
                            style: const TextStyle(
                              color: FC.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: FC.accent,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ViewToggleButton(
                      icon: Icons.grid_view_rounded,
                      selected: _viewMode == _ViewMode.grid,
                      onTap: () => setState(() => _viewMode = _ViewMode.grid),
                    ),
                    _ViewToggleButton(
                      icon: Icons.view_list_rounded,
                      selected: _viewMode == _ViewMode.list,
                      onTap: () => setState(() => _viewMode = _ViewMode.list),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Results ──
              Expanded(child: _buildResults(results)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResults(List<UserModel> results) {
    if (_query.isEmpty && _filters.isDefault) {
      return _EmptyState(
        icon: Icons.search_rounded,
        message: 'Search for users',
        subtitle: 'Find your people, your vibe, your universe 🌈',
      );
    }

    if (results.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_off_rounded,
        message: 'No users found',
        subtitle: 'Try adjusting your search or filters',
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _viewMode == _ViewMode.grid
            ? GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, i) => UserSearchCard(user: results[i]),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: results.length,
                itemBuilder: (context, i) => UserSearchTile(user: results[i]),
              ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected ? FC.primary : FC.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? FC.primary : FC.border),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? Colors.white : FC.textMid,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: FC.textLo),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              color: FC.textHi,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: FC.textLo, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
