import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story_model.dart';

class StoryService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Active stories from the last 24 h.
  static Stream<List<StoryModel>> activeStories() {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    return _db
        .collection('stories')
        .where('createdAt', isGreaterThan: cutoff)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(StoryModel.fromDoc).toList());
  }

  static Future<void> markViewed(String storyId) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('stories').doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Creates a new story doc. Call this after the image is already
  /// uploaded to Cloudinary — imageUrl is the returned secure_url.
  static Future<void> createStory({
    required String userId,
    required String userName,
    required String imageUrl,
  }) async {
    final now = DateTime.now();
    await _db.collection('stories').add({
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'viewedBy': <String>[],
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    });
  }
}
