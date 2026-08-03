import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';

class CommentService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Stream<List<CommentModel>> commentsStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(CommentModel.fromDoc).toList());
  }

  static Future<void> addComment(String postId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = _auth.currentUser!;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'User';

    await _db.collection('posts').doc(postId).collection('comments').add({
      'userId': user.uid,
      'userName': userName,
      'text': trimmed,
      'likedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final postDoc = await _db.collection('posts').doc(postId).get();
    final postOwnerId = postDoc.data()?['userId'];

    if (postOwnerId != null && postOwnerId != user.uid) {
      await _db.collection('notifications').add({
        'receiverId': postOwnerId,
        'senderName': userName,
        'type': 'comment',
        'message': '$userName commented on your post 💬',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> deleteComment(String postId, String commentId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  static Future<void> toggleLike(String postId, CommentModel comment) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(comment.id);

    if (comment.likedBy.contains(uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }
}
