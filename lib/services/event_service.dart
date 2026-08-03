import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';

class EventService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<EventModel>> streamEvents() {
    return _db
        .collection('events')
        .orderBy('eventDate')
        .snapshots()
        .map((snap) => snap.docs.map(EventModel.fromDoc).toList());
  }

  static Stream<EventModel?> streamEvent(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? EventModel.fromDoc(doc) : null);
  }

  static Future<void> createEvent({
    required String title,
    required String location,
    required String description,
    required DateTime eventDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    await _db.collection('events').add({
      'title': title,
      'location': location,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdBy': user.uid,
      'createdByName': userData?['name'] ?? 'User',
      'createdByImage': userData?['profileImage'] ?? '',
      'joinedUsers': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns true if this toggle resulted in the user JOINING the event
  /// (false if it resulted in them leaving).
  static Future<bool> toggleJoin(
    String eventId,
    List<String> joinedUsers,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = _db.collection('events').doc(eventId);

    if (joinedUsers.contains(uid)) {
      await ref.update({
        'joinedUsers': FieldValue.arrayRemove([uid]),
      });
      return false;
    } else {
      await ref.update({
        'joinedUsers': FieldValue.arrayUnion([uid]),
      });
      return true;
    }
  }
}
