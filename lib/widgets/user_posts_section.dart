import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../screens/comments_screen.dart';

class UserPostsSection extends StatelessWidget {
  final String userId;

  const UserPostsSection({super.key, required this.userId});

  Future<void> toggleLike(
    String postId,
    List likedBy,
    String postOwnerId,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (likedBy.contains(uid)) {
      await docRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([uid]),
      });

      if (uid != postOwnerId) {
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        final senderName = currentUserDoc.data()?['name'] ?? 'User';

        await FirebaseFirestore.instance.collection('notifications').add({
          'receiverId': postOwnerId,
          'senderName': senderName,
          'type': 'like',
          'message': '$senderName liked your post ❤️',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  String getTimeAgo(Timestamp? createdAt) {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final postTime = createdAt.toDate();

    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return DateFormat('dd MMM yyyy').format(postTime);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              "No posts yet",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return Column(
          children: posts.map((doc) {
            final post = doc.data() as Map<String, dynamic>;

            final likedBy = List<String>.from(post['likedBy'] ?? []);

            final isLiked = likedBy.contains(currentUserId);

            return Card(
              color: Colors.grey.shade900,
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTimeAgo(post['createdAt']),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      post['text'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(doc.id)
                          .collection('comments')
                          .snapshots(),
                      builder: (context, commentSnapshot) {
                        final commentCount =
                            commentSnapshot.data?.docs.length ?? 0;

                        return Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                toggleLike(doc.id, likedBy, post['userId']);
                              },
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                            ),

                            Text(
                              '${post['likes'] ?? 0}',
                              style: const TextStyle(color: Colors.white),
                            ),

                            const SizedBox(width: 20),

                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CommentsScreen(postId: doc.id),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.comment_outlined,
                                color: Colors.white70,
                              ),
                            ),

                            Text(
                              commentCount.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
