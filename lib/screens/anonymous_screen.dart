import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_anonymous_post_screen.dart';
import 'anonymous_comments_screen.dart';

class AnonymousScreen extends StatelessWidget {
  const AnonymousScreen({super.key});

  Future<void> toggleLike(String postId, List likedBy) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final docRef = FirebaseFirestore.instance
        .collection('anonymous_posts')
        .doc(postId);

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
    }
  }

  Future<void> deletePost(String postId) async {
    await FirebaseFirestore.instance
        .collection('anonymous_posts')
        .doc(postId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Anonymous"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateAnonymousPostScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('anonymous_posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                "No anonymous posts yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index].data() as Map<String, dynamic>;

                  final likedBy = List<String>.from(post['likedBy'] ?? []);

                  final isLiked = likedBy.contains(currentUserId);

                  final isOwner = post['userId'] == currentUserId;

                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.pink,
                                child: Icon(
                                  Icons.visibility_off,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Expanded(
                                child: Text(
                                  "Anonymous User",
                                  style: TextStyle(
                                    color: Colors.pink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              if (isOwner)
                                PopupMenuButton<String>(
                                  color: Colors.grey.shade900,
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      await deletePost(posts[index].id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete Post',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Text(
                            post['text'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 15),

                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('anonymous_posts')
                                .doc(posts[index].id)
                                .collection('comments')
                                .snapshots(),
                            builder: (context, commentSnapshot) {
                              final commentCount =
                                  commentSnapshot.data?.docs.length ?? 0;

                              return Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      toggleLike(posts[index].id, likedBy);
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AnonymousCommentsScreen(
                                                postId: posts[index].id,
                                              ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
