import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportDialog extends StatelessWidget {
  final String postId;
  final String reportedUserId;

  const ReportDialog({
    super.key,
    required this.postId,
    required this.reportedUserId,
  });

  Future<void> _submitReport(BuildContext context, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': FirebaseAuth.instance.currentUser!.uid,
        'reportedUserId': reportedUserId,
        'postId': postId,
        'reason': reason,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _reasonTile(BuildContext context, String reason) {
    return ListTile(
      leading: const Icon(Icons.flag, color: Colors.orange),
      title: Text(
        reason,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _submitReport(context, reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text('Report Post', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _reasonTile(context, 'Harassment'),
          _reasonTile(context, 'Spam'),
          _reasonTile(context, 'Hate Speech'),
          _reasonTile(context, 'Inappropriate Content'),
          _reasonTile(context, 'Fake Information'),
          _reasonTile(context, 'Other'),
        ],
      ),
    );
  }
}
