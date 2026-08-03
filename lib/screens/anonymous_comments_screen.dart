import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnonymousCommentsScreen extends StatefulWidget {
  final String postId;

  const AnonymousCommentsScreen({super.key, required this.postId});

  @override
  State<AnonymousCommentsScreen> createState() =>
      _AnonymousCommentsScreenState();
}

class _AnonymousCommentsScreenState extends State<AnonymousCommentsScreen> {
  final TextEditingController commentController = TextEditingController();

  Future<void> addComment() async {
    if (commentController.text.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('anonymous_posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
          'text': commentController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

    commentController.clear();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Anonymous Comments"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('anonymous_posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      "No comments yet",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment =
                        comments[index].data() as Map<String, dynamic>;

                    return Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(
                            Icons.visibility_off,
                            color: Colors.white,
                          ),
                        ),
                        title: const Text(
                          "Anonymous User",
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          comment['text'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Comment anonymously...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: addComment,
                  icon: const Icon(Icons.send, color: Colors.pink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
