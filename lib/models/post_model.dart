import 'package:cloud_firestore/cloud_firestore.dart';

class PollOption {
  final String text;
  final int votes;
  final List<String> votedBy;

  const PollOption({
    required this.text,
    required this.votes,
    required this.votedBy,
  });

  factory PollOption.fromMap(Map<String, dynamic> m) => PollOption(
    text: m['text'] ?? '',
    votes: (m['votes'] ?? 0) as int,
    votedBy: List<String>.from(m['votedBy'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'text': text,
    'votes': votes,
    'votedBy': votedBy,
  };
}

class PollData {
  final String question;
  final List<PollOption> options;
  final int totalVotes;

  const PollData({
    required this.question,
    required this.options,
    required this.totalVotes,
  });

  factory PollData.fromMap(Map<String, dynamic> m) => PollData(
    question: m['question'] ?? '',
    options: (m['options'] as List? ?? [])
        .map((o) => PollOption.fromMap(Map<String, dynamic>.from(o)))
        .toList(),
    totalVotes: (m['totalVotes'] ?? 0) as int,
  );
}

class EventData {
  final String title;
  final Timestamp? dateTime;
  final String? location;

  const EventData({required this.title, this.dateTime, this.location});

  factory EventData.fromMap(Map<String, dynamic> m) => EventData(
    title: m['title'] ?? '',
    dateTime: m['dateTime'] as Timestamp?,
    location: m['location'] as String?,
  );
}

/// Structured song data attached to a post, sourced from the iTunes
/// Search API (real track, real 30s preview clip).
class MusicData {
  final String trackName;
  final String artistName;
  final String? artworkUrl;
  final String? previewUrl;

  const MusicData({
    required this.trackName,
    required this.artistName,
    this.artworkUrl,
    this.previewUrl,
  });

  factory MusicData.fromMap(Map<String, dynamic> m) => MusicData(
    trackName: m['trackName'] ?? '',
    artistName: m['artistName'] ?? '',
    artworkUrl: m['artworkUrl'] as String?,
    previewUrl: m['previewUrl'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'trackName': trackName,
    'artistName': artistName,
    'artworkUrl': artworkUrl,
    'previewUrl': previewUrl,
  };
}

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String handle;
  final String text;
  final int likes;
  final List<String> likedBy;
  final List<String> savedBy;
  final String? imageUrl;
  final String? videoUrl;
  final String? location;
  final String? mood;
  final MusicData? musicData;
  final List<String> hashtags;
  final PollData? poll;
  final EventData? event;
  final bool isAnonymous;
  final Timestamp? createdAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.handle,
    required this.text,
    required this.likes,
    required this.likedBy,
    required this.savedBy,
    this.imageUrl,
    this.videoUrl,
    this.location,
    this.mood,
    this.musicData,
    this.hashtags = const [],
    this.poll,
    this.event,
    this.isAnonymous = false,
    this.createdAt,
  });

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    PollData? poll;
    if (d['poll'] != null) {
      poll = PollData.fromMap(Map<String, dynamic>.from(d['poll']));
    }

    EventData? event;
    if (d['event'] != null) {
      event = EventData.fromMap(Map<String, dynamic>.from(d['event']));
    }

    MusicData? musicData;
    if (d['musicData'] != null) {
      musicData = MusicData.fromMap(Map<String, dynamic>.from(d['musicData']));
    }

    return PostModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? 'User',
      handle: d['handle'] ?? '',
      text: d['text'] ?? '',
      likes: (d['likes'] ?? 0) as int,
      likedBy: List<String>.from(d['likedBy'] ?? []),
      savedBy: List<String>.from(d['savedBy'] ?? []),
      imageUrl: d['imageUrl'] as String?,
      videoUrl: d['videoUrl'] as String?,
      location: d['location'] as String?,
      mood: d['mood'] as String?,
      musicData: musicData,
      hashtags: List<String>.from(d['hashtags'] ?? []),
      poll: poll,
      event: event,
      isAnonymous: d['isAnonymous'] ?? false,
      createdAt: d['createdAt'] as Timestamp?,
    );
  }
}
