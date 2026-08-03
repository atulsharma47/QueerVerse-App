import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final List<String> likedBy;
  final Timestamp? createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.likedBy,
    this.createdAt,
  });

  int get likeCount => likedBy.length;

  factory CommentModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? 'User',
      text: d['text'] ?? '',
      likedBy: List<String>.from(d['likedBy'] ?? []),
      createdAt: d['createdAt'] as Timestamp?,
    );
  }
}
