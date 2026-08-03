import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/story_model.dart';
import '../../services/story_service.dart';
import '../../screens/create_story_screen.dart';
import '../../screens/story_viewer_screen.dart';
import 'story_avatar.dart';
import 'feed_app_bar.dart';

class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return SizedBox(
      height: 104,
      child: StreamBuilder<List<StoryModel>>(
        stream: StoryService.activeStories(),
        builder: (context, snap) {
          final stories = snap.data ?? [];

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              StoryAvatar.self(
                uid: uid,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
                ),
              ),
              ...List.generate(stories.length, (index) {
                final s = stories[index];
                return StoryAvatar.fromStory(
                  story: s,
                  isMine: s.userId == uid,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryViewerScreen(
                        stories: stories,
                        initialIndex: index,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
