import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> markAllAsRead() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .get();

    for (final doc in notifications.docs) {
      final data = doc.data();

      if (data['receiverId'] == currentUserId && data['isRead'] == false) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final notifications = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return data['receiverId'] == currentUserId;
          }).toList();

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink,
                    child: Icon(
                      _getIcon(data['type'] ?? ''),
                      color: Colors.white,
                    ),
                  ),

                  title: Text(
                    data['message'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    data['senderName'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),

                  trailing: (data['isRead'] ?? false)
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add;

      case 'like':
        return Icons.favorite;

      case 'comment':
        return Icons.comment;

      default:
        return Icons.notifications;
    }
  }
}
