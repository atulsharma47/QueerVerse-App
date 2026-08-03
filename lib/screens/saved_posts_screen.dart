import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_model.dart';
import '../widgets/feed/post_card.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  static const _bg = Color(0xFF0A0A12);
  static const _textLo = Color(0xFFB0B0C8);
  static const _primary = Color(0xFF8B5CF6);

  /// Fetches the actual post documents for a list of saved_posts docs.
  /// Skips any postId that no longer resolves to a real post (e.g. deleted).
  Future<List<PostModel>> _fetchPosts(
    List<QueryDocumentSnapshot> savedDocs,
  ) async {
    final postIds = savedDocs
        .map((d) => (d.data() as Map<String, dynamic>)['postId'] as String?)
        .whereType<String>()
        .toList();

    if (postIds.isEmpty) return [];

    final futures = postIds.map(
      (id) => FirebaseFirestore.instance.collection('posts').doc(id).get(),
    );
    final snaps = await Future.wait(futures);

    return snaps
        .where((s) => s.exists)
        .map((s) => PostModel.fromDoc(s))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Saved Posts', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text(
                'You need to be signed in to see saved posts.',
                style: TextStyle(color: _textLo),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('saved_posts')
                  .where('userId', isEqualTo: uid)
                  .orderBy('savedAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Something went wrong loading saved posts.\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _textLo),
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                final savedDocs = snap.data!.docs;
                if (savedDocs.isEmpty) {
                  return const _EmptySaved();
                }

                return FutureBuilder<List<PostModel>>(
                  future: _fetchPosts(savedDocs),
                  builder: (context, postSnap) {
                    if (postSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _primary),
                      );
                    }
                    if (postSnap.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load post details.\n${postSnap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _textLo),
                        ),
                      );
                    }

                    final posts = postSnap.data ?? [];
                    if (posts.isEmpty) return const _EmptySaved();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: posts.length,
                      itemBuilder: (_, i) =>
                          PostCard(post: posts[i], currentUserId: uid),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              color: Color(0xFFB0B0C8),
              size: 56,
            ),
            SizedBox(height: 16),
            Text(
              'No saved posts yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tap the bookmark icon on any post to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB0B0C8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
