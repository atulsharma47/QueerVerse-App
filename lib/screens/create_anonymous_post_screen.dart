import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAnonymousPostScreen extends StatefulWidget {
  const CreateAnonymousPostScreen({super.key});

  @override
  State<CreateAnonymousPostScreen> createState() =>
      _CreateAnonymousPostScreenState();
}

class _CreateAnonymousPostScreenState extends State<CreateAnonymousPostScreen> {
  final TextEditingController postController = TextEditingController();

  bool isLoading = false;

  Future<void> createPost() async {
    if (postController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('anonymous_posts').add({
      'userId': user?.uid,
      'text': postController.text.trim(),
      'likes': 0,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Anonymous Post"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: postController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Share anonymously...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : createPost,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Post Anonymously"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
