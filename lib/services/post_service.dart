import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Stream<List<PostModel>> allPosts() => _db
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PostModel.fromDoc).toList());

  static Stream<List<PostModel>> followingPosts() {
    final uid = _auth.currentUser!.uid;
    return _db
        .collection('follows')
        .where('followerId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
          final ids = snap.docs.map((d) => d['followingId'] as String).toList();
          if (ids.isEmpty) return <PostModel>[];
          final posts = await _db
              .collection('posts')
              .where('userId', whereIn: ids)
              .orderBy('createdAt', descending: true)
              .get();
          return posts.docs.map(PostModel.fromDoc).toList();
        });
  }

  static Future<void> toggleLike(PostModel post) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db.collection('posts').doc(post.id);
    final liked = post.likedBy.contains(uid);
    await ref.update(
      liked
          ? {
              'likes': FieldValue.increment(-1),
              'likedBy': FieldValue.arrayRemove([uid]),
            }
          : {
              'likes': FieldValue.increment(1),
              'likedBy': FieldValue.arrayUnion([uid]),
            },
    );
    if (!liked && uid != post.userId) {
      final me = await _db.collection('users').doc(uid).get();
      final name = (me.data() ?? {})['name'] ?? 'User';
      await _db.collection('notifications').add({
        'receiverId': post.userId,
        'senderName': name,
        'type': 'like',
        'message': '$name liked your post ❤️',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> toggleSave(PostModel post) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db.collection('posts').doc(post.id);
    final saved = post.savedBy.contains(uid);
    await ref.update(
      saved
          ? {
              'savedBy': FieldValue.arrayRemove([uid]),
            }
          : {
              'savedBy': FieldValue.arrayUnion([uid]),
            },
    );
    final savedRef = _db.collection('saved_posts').doc('${uid}_${post.id}');
    saved
        ? await savedRef.delete()
        : await savedRef.set({
            'userId': uid,
            'postId': post.id,
            'savedAt': FieldValue.serverTimestamp(),
          });
  }

  static Future<void> deletePost(String postId) =>
      _db.collection('posts').doc(postId).delete();

  static Future<void> reportPost({
    required String postId,
    required String reportedUserId,
    required String reason,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('reports').add({
      'postId': postId,
      'reportedUserId': reportedUserId,
      'reportedBy': uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<int> commentCount(String postId) => _db
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .snapshots()
      .map((s) => s.docs.length);

  /// Casts one poll vote (or switches an existing vote) for [postId].
  /// Wrapped in a transaction so simultaneous votes can't corrupt counts.
  static Future<void> votePoll(String postId, int optionIndex) async {
    final uid = _auth.currentUser!.uid;
    final ref = _db.collection('posts').doc(postId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null || data['poll'] == null) return;

      final poll = Map<String, dynamic>.from(data['poll']);
      final options = List<Map<String, dynamic>>.from(
        (poll['options'] as List).map((o) => Map<String, dynamic>.from(o)),
      );

      int previousIndex = -1;
      for (var i = 0; i < options.length; i++) {
        final votedBy = List<String>.from(options[i]['votedBy'] ?? []);
        if (votedBy.contains(uid)) {
          previousIndex = i;
          break;
        }
      }

      if (previousIndex == optionIndex) return;

      int totalVotes = (poll['totalVotes'] ?? 0) as int;

      if (previousIndex != -1) {
        final prevVotedBy = List<String>.from(
          options[previousIndex]['votedBy'] ?? [],
        );
        prevVotedBy.remove(uid);
        options[previousIndex]['votedBy'] = prevVotedBy;
        options[previousIndex]['votes'] =
            (options[previousIndex]['votes'] as int) - 1;
      } else {
        totalVotes += 1;
      }

      final newVotedBy = List<String>.from(
        options[optionIndex]['votedBy'] ?? [],
      );
      newVotedBy.add(uid);
      options[optionIndex]['votedBy'] = newVotedBy;
      options[optionIndex]['votes'] =
          (options[optionIndex]['votes'] as int) + 1;

      poll['options'] = options;
      poll['totalVotes'] = totalVotes;

      tx.update(ref, {'poll': poll});
    });
  }

  /// Creates a new post. Call this from CreatePostScreen.
  ///
  /// [pollOptions] should be a list of plain option strings (2-4 items).
  /// [eventData] should contain 'title', 'dateTime' (DateTime), 'location'.
  /// [musicData] should contain 'trackName', 'artistName', 'artworkUrl',
  /// 'previewUrl' — exactly the map shape returned by the music search sheet.
  static Future<void> createPost({
    required String text,
    String? imageUrl,
    String? videoUrl,
    String? location,
    String? mood,
    Map<String, dynamic>? musicData,
    List<String> hashtags = const [],
    String? pollQuestion,
    List<String>? pollOptions,
    Map<String, dynamic>? eventData,
    String visibility = 'public',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('You must be logged in to post.');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    Map<String, dynamic>? poll;
    if (pollOptions != null && pollOptions.length >= 2) {
      poll = {
        'question': pollQuestion ?? '',
        'options': pollOptions
            .map((o) => {'text': o, 'votes': 0, 'votedBy': <String>[]})
            .toList(),
        'totalVotes': 0,
      };
    }

    Map<String, dynamic>? event;
    if (eventData != null &&
        (eventData['title'] as String?)?.isNotEmpty == true) {
      event = {
        'title': eventData['title'],
        'dateTime': eventData['dateTime'] != null
            ? Timestamp.fromDate(eventData['dateTime'] as DateTime)
            : null,
        'location': eventData['location'],
      };
    }

    await _db.collection('posts').add({
      'userId': user.uid,
      'userName': userData['name'] ?? 'User',
      'handle': userData['handle'] ?? '',
      'text': text.trim(),
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'location': location,
      'mood': mood,
      'musicData': musicData,
      'hashtags': hashtags,
      'poll': poll,
      'event': event,
      'visibility': visibility,
      'likes': 0,
      'likedBy': <String>[],
      'savedBy': <String>[],
      'isAnonymous': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
