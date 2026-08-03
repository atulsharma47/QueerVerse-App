import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static Stream<UserModel?> userStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDoc(doc) : null);
  }

  static Future<UserModel?> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromDoc(doc) : null;
  }

  static Future<void> updateProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------- Presence ----------

  static Future<void> setOnline(String uid) async {
    await _db.collection('users').doc(uid).set({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setOffline(String uid) async {
    await _db.collection('users').doc(uid).set({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------- Verification ----------

  static Future<void> syncEmailVerified(String uid, bool verified) async {
    await _db.collection('users').doc(uid).set({
      'isEmailVerified': verified,
    }, SetOptions(merge: true));
  }

  static Future<void> markIdVerified(String uid, String idDocumentUrl) async {
    await _db.collection('users').doc(uid).set({
      'isIdVerified': true,
      'idDocumentUrl': idDocumentUrl,
    }, SetOptions(merge: true));
  }

  // ---------- Premium (admin-controlled) ----------

  static Future<void> setPremium(String uid, bool isPremium) async {
    await _db.collection('users').doc(uid).set({
      'isPremium': isPremium,
    }, SetOptions(merge: true));
  }

  static Future<UserModel?> findUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromDoc(query.docs.first);
  }

  // ---------- Search (NEW) ----------

  /// All users except [excludeUid], as live [UserModel]s, for the search
  /// screen. Filtering/sorting happens client-side in the screen — same
  /// approach the rest of the app already uses for the feed.
  static Stream<List<UserModel>> searchableUsersStream(String excludeUid) {
    return _db
        .collection('users')
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => doc.id != excludeUid)
              .map(UserModel.fromDoc)
              .toList(),
        );
  }

  // ---------- Likes (NEW — mirrors PostService.toggleLike) ----------

  static Future<void> toggleLikeUser(
    String currentUid,
    String targetUid,
  ) async {
    final ref = _db.collection('users').doc(targetUid);
    final doc = await ref.get();
    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);

    if (likedBy.contains(currentUid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([currentUid]),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([currentUid]),
      });
    }
  }
}
