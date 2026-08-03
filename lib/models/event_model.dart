import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String location;
  final String description;
  final Timestamp? eventDate;
  final String createdBy;
  final String createdByName;
  final String createdByImage;
  final List<String> joinedUsers;
  final Timestamp? createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.eventDate,
    required this.createdBy,
    required this.createdByName,
    required this.createdByImage,
    required this.joinedUsers,
    required this.createdAt,
  });

  factory EventModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return EventModel(
      id: doc.id,
      title: d['title'] ?? '',
      location: d['location'] ?? '',
      description: d['description'] ?? '',
      eventDate: d['eventDate'] as Timestamp?,
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? 'User',
      createdByImage: d['createdByImage'] ?? '',
      joinedUsers: List<String>.from(d['joinedUsers'] ?? []),
      createdAt: d['createdAt'] as Timestamp?,
    );
  }

  bool isJoinedBy(String? uid) => uid != null && joinedUsers.contains(uid);

  int get participantCount => joinedUsers.length;
}
