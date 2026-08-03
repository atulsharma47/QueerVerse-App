import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/story_model.dart';
import 'feed_app_bar.dart';

class StoryAvatar extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isSelf;
  final bool isViewed;
  final VoidCallback? onTap;

  const StoryAvatar._({
    required this.label,
    this.imageUrl,
    this.isSelf = false,
    this.isViewed = false,
    this.onTap,
  });

  // ── "Your Story" slot ──
  factory StoryAvatar.self({required String uid, VoidCallback? onTap}) {
    return StoryAvatar._(label: 'Your Story', isSelf: true, onTap: onTap);
  }

  // ── Story from Firestore ──
  factory StoryAvatar.fromStory({
    required StoryModel story,
    required bool isMine,
    VoidCallback? onTap,
  }) {
    return StoryAvatar._(
      label: story.userName,
      imageUrl: story.imageUrl,
      isSelf: isMine,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelf || isViewed
                        ? null
                        : const LinearGradient(
                            colors: [FC.primary, FC.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: (isSelf || isViewed)
                        ? Border.all(color: FC.border, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: FC.surface,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl != null
                        ? Image.network(imageUrl!, fit: BoxFit.cover)
                        : Center(
                            child: isSelf
                                ? const Icon(
                                    Icons.add,
                                    color: FC.accent,
                                    size: 22,
                                  )
                                : Text(
                                    label.isNotEmpty
                                        ? label[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                  ),
                ),
                if (!isSelf)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: FC.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: FC.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 62,
              child: Text(
                label,
                style: const TextStyle(color: FC.textMid, fontSize: 10),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
