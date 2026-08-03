import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final Timestamp? timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      timestamp: d['timestamp'] as Timestamp?,
    );
  }
}
