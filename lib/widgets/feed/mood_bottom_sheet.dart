import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feed_app_bar.dart';

const _moods = [
  {'emoji': '😊', 'label': 'Happy'},
  {'emoji': '😔', 'label': 'Sad'},
  {'emoji': '☕', 'label': 'Coffee?'},
  {'emoji': '🎮', 'label': 'Gaming'},
  {'emoji': '🏳️‍🌈', 'label': 'Pride'},
  {'emoji': '🌙', 'label': 'Night Owl'},
  {'emoji': '🤝', 'label': 'Looking for Friends'},
  {'emoji': '🎬', 'label': 'Movie Night'},
  {'emoji': '🎵', 'label': 'Music Vibes'},
  {'emoji': '✈️', 'label': 'Travelling'},
];

class MoodBottomSheet extends StatelessWidget {
  const MoodBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoodBottomSheet(),
    );
  }

  Future<void> _setMood(String emoji, String label) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'mood': label,
      'moodEmoji': emoji,
      'moodSetAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FC.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FC.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FC.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Set Your Mood',
            style: TextStyle(
              color: FC.textHi,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _moods.map((m) {
              return GestureDetector(
                onTap: () async {
                  await _setMood(m['emoji']!, m['label']!);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: FC.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FC.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m['emoji']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        m['label']!,
                        style: const TextStyle(color: FC.textMid, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
