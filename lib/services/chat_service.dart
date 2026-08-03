import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String chatIdFor(String otherUserId) {
    final currentUserId = _auth.currentUser!.uid;
    return currentUserId.compareTo(otherUserId) < 0
        ? '${currentUserId}_$otherUserId'
        : '${otherUserId}_$currentUserId';
  }

  static Stream<List<ChatModel>> userChatsStream() {
    final currentUserId = _auth.currentUser!.uid;
    return _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChatModel.fromDoc).toList());
  }

  static Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs.map(MessageModel.fromDoc).toList());
  }

  static Future<void> sendMessage(String otherUserId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final currentUser = _auth.currentUser!;
    final chatId = chatIdFor(otherUserId);
    final chatDoc = _db.collection('chats').doc(chatId);

    await chatDoc.set({
      'participants': [currentUser.uid, otherUserId],
      'lastMessage': trimmed,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': {
        currentUser.uid: 0,
        otherUserId: FieldValue.increment(1),
      },
    }, SetOptions(merge: true));

    await chatDoc.collection('messages').add({
      'senderId': currentUser.uid,
      'senderEmail': currentUser.email,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markRead(String chatId) async {
    final currentUserId = _auth.currentUser!.uid;
    await _db.collection('chats').doc(chatId).set({
      'unreadCounts': {currentUserId: 0},
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> fetchUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }
}
