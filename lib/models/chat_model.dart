import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final Map<String, dynamic> unreadCounts;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCounts,
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      lastMessage: d['lastMessage'] ?? '',
      lastMessageTime: d['lastMessageTime'] as Timestamp?,
      unreadCounts: Map<String, dynamic>.from(d['unreadCounts'] ?? {}),
    );
  }

  String otherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int unreadCountFor(String currentUserId) {
    return (unreadCounts[currentUserId] ?? 0) as int;
  }
}
