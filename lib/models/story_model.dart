import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String? imageUrl;
  final List<String> viewedBy;
  final Timestamp? createdAt;
  final Timestamp? expiresAt;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.imageUrl,
    required this.viewedBy,
    this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.toDate());
  }

  factory StoryModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? 'User',
      imageUrl: d['imageUrl'] as String?,
      viewedBy: List<String>.from(d['viewedBy'] ?? []),
      createdAt: d['createdAt'] as Timestamp?,
      expiresAt: d['expiresAt'] as Timestamp?,
    );
  }
}
