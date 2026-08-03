import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../screens/comments_screen.dart';
import '../../screens/edit_post_screen.dart';
import '../../screens/user_profile_screen.dart';
import '../report_dialog.dart';
import 'feed_app_bar.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;

  const PostCard({super.key, required this.post, required this.currentUserId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartAnim;
  bool _showHeart = false;

  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _isPlayingMusic = false;

  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoMuted = true;
  bool _showPlayIcon = true;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));

    if (widget.post.videoUrl != null) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!))
            ..setLooping(true)
            ..setVolume(0) // start muted, matches _videoMuted = true
            ..initialize().then((_) {
              if (mounted) setState(() => _videoInitialized = true);
            });
    }
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    _musicPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  bool get _isOwner => widget.currentUserId == widget.post.userId;
  bool get _isLiked => widget.post.likedBy.contains(widget.currentUserId);
  bool get _isSaved => widget.post.savedBy.contains(widget.currentUserId);

  void _doubleTap() {
    if (!_isLiked) PostService.toggleLike(widget.post);
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _sharePost() {
    final post = widget.post;
    final name = post.isAnonymous ? 'Someone' : post.userName;
    final buffer = StringBuffer();
    buffer.write('$name on QueerVerse:\n\n"${post.text}"');
    if (post.imageUrl != null) buffer.write('\n\n${post.imageUrl}');
    if (post.videoUrl != null) buffer.write('\n\n${post.videoUrl}');
    Share.share(buffer.toString(), subject: 'Check this out on QueerVerse');
  }

  void _toggleVideoPlayback() {
    final controller = _videoController;
    if (controller == null || !_videoInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _showPlayIcon = true;
      } else {
        controller.play();
        _showPlayIcon = false;
      }
    });
  }

  void _toggleVideoMute() {
    final controller = _videoController;
    if (controller == null) return;
    setState(() {
      _videoMuted = !_videoMuted;
      controller.setVolume(_videoMuted ? 0 : 1);
    });
  }

  Future<void> _toggleMusicPreview(String url) async {
    if (_isPlayingMusic) {
      await _musicPlayer.stop();
      if (mounted) setState(() => _isPlayingMusic = false);
    } else {
      await _musicPlayer.stop();
      await _musicPlayer.play(UrlSource(url));
      if (mounted) setState(() => _isPlayingMusic = true);
      _musicPlayer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _isPlayingMusic = false);
      });
    }
  }

  String get _timeAgo {
    if (widget.post.createdAt == null) return '';
    final diff = DateTime.now().difference(widget.post.createdAt!.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(widget.post.createdAt!.toDate());
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FC.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: FC.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: post.userId),
                    ),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [FC.primary, FC.accent]),
                    ),
                    child: Center(
                      child: Text(
                        post.isAnonymous
                            ? '?'
                            : (post.userName.isNotEmpty
                                  ? post.userName[0].toUpperCase()
                                  : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: post.userId),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.isAnonymous ? 'Anonymous' : post.userName,
                              style: const TextStyle(
                                color: FC.textHi,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: FC.primary,
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (post.handle.isNotEmpty) ...[
                              Text(
                                '@${post.handle}',
                                style: const TextStyle(
                                  color: FC.textLo,
                                  fontSize: 12,
                                ),
                              ),
                              const Text(
                                ' · ',
                                style: TextStyle(
                                  color: FC.textLo,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            Text(
                              _timeAgo,
                              style: const TextStyle(
                                color: FC.textLo,
                                fontSize: 12,
                              ),
                            ),
                            if (post.location != null) ...[
                              const Text(
                                ' · ',
                                style: TextStyle(
                                  color: FC.textLo,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(
                                Icons.location_on_outlined,
                                color: FC.textLo,
                                size: 11,
                              ),
                              Text(
                                post.location!,
                                style: const TextStyle(
                                  color: FC.textLo,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (post.mood != null) ...[
                              const Text(
                                ' · ',
                                style: TextStyle(
                                  color: FC.textLo,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'feeling ${post.mood}',
                                style: const TextStyle(
                                  color: FC.textLo,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (post.musicData != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildMusicRow(post.musicData!),
                          ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: const Color(0xFF1E1E2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: FC.border),
                  ),
                  icon: const Icon(
                    Icons.more_horiz,
                    color: FC.textMid,
                    size: 20,
                  ),
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditPostScreen(
                              postId: post.id,
                              currentText: post.text,
                            ),
                          ),
                        );
                        break;
                      case 'delete':
                        await PostService.deletePost(post.id);
                        break;
                      case 'report':
                        showDialog(
                          context: context,
                          builder: (_) => ReportDialog(
                            postId: post.id,
                            reportedUserId: post.userId,
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (_) => _isOwner
                      ? [
                          _mi('edit', 'Edit', Colors.white),
                          _mi('delete', 'Delete', Colors.redAccent),
                          _mi('copy', 'Copy Link', FC.textMid),
                        ]
                      : [
                          _mi('report', 'Report Post', Colors.orange),
                          _mi('mute', 'Mute User', FC.textMid),
                          _mi('block', 'Block User', Colors.redAccent),
                        ],
                ),
              ],
            ),
          ),

          // ── Photo ──
          if (post.imageUrl != null)
            GestureDetector(
              onDoubleTap: _doubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    child: Image.network(
                      post.imageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_showHeart)
                    ScaleTransition(
                      scale: _heartAnim,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                ],
              ),
            ),

          // ── Video (inline player) ──
          if (post.videoUrl != null) _buildVideo(),

          // ── Text (with hashtag highlighting) ──
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: _highlightedText(post.text),
            ),

          // ── Poll ──
          if (post.poll != null) _buildPoll(post),

          // ── Event ──
          if (post.event != null) _buildEvent(post.event!),

          // ── Actions ──
          StreamBuilder<int>(
            stream: PostService.commentCount(post.id),
            builder: (_, snap) {
              final cc = snap.data ?? 0;
              return Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
                child: Row(
                  children: [
                    _ActionBtn(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent,
                      label: _fmt(post.likes),
                      onTap: () => PostService.toggleLike(post),
                    ),
                    _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: FC.textMid,
                      label: _fmt(cc),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CommentsScreen(postId: post.id),
                      ),
                    ),
                    _ActionBtn(
                      icon: Icons.reply_rounded,
                      color: FC.textMid,
                      label: '',
                      onTap: _sharePost,
                    ),
                    const Spacer(),
                    _ActionBtn(
                      icon: _isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _isSaved ? FC.primary : FC.textMid,
                      label: '',
                      onTap: () => PostService.toggleSave(post),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Music
  // -----------------------------------------------------------------

  Widget _buildMusicRow(MusicData music) {
    final url = music.previewUrl;

    return GestureDetector(
      onTap: url == null ? null : () => _toggleMusicPreview(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: FC.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlayingMusic
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              color: FC.primary,
              size: 16,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '${music.trackName} · ${music.artistName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: FC.primary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Video — inline player, plays in place instead of leaving the app
  // -----------------------------------------------------------------

  Widget _buildVideo() {
    final controller = _videoController;

    if (controller == null || !_videoInitialized) {
      // Loading state — shown while the video is buffering its first frame
      return Container(
        width: double.infinity,
        height: 220,
        color: FC.card,
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),

            // Play icon — shown when paused
            AnimatedOpacity(
              opacity: _showPlayIcon ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),

            // Mute toggle — bottom right, always visible
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: _toggleVideoMute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Hashtag highlighting
  // -----------------------------------------------------------------

  Widget _highlightedText(String text) {
    final regex = RegExp(r'(#\w+)');
    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            color: FC.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: FC.textHi, fontSize: 15, height: 1.5),
        children: spans,
      ),
    );
  }

  // -----------------------------------------------------------------
  // Poll
  // -----------------------------------------------------------------

  Widget _buildPoll(PostModel post) {
    final poll = post.poll!;
    final total = poll.totalVotes;
    final myVoteIndex = poll.options.indexWhere(
      (o) => o.votedBy.contains(widget.currentUserId),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FC.border.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FC.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: const TextStyle(
                color: FC.textHi,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < poll.options.length; i++) ...[
              _pollOptionTile(
                post.id,
                i,
                poll.options[i],
                total,
                myVoteIndex == i,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '$total vote${total == 1 ? '' : 's'}',
              style: const TextStyle(color: FC.textLo, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pollOptionTile(
    String postId,
    int index,
    PollOption option,
    int total,
    bool selected,
  ) {
    final pct = total == 0 ? 0.0 : option.votes / total;

    return GestureDetector(
      onTap: () => PostService.votePoll(postId, index),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: FC.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? FC.primary : FC.border,
                width: selected ? 1.5 : 1,
              ),
            ),
          ),
          FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: FC.primary.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_circle,
                        color: FC.primary,
                        size: 15,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      option.text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FC.textHi, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(color: FC.textLo, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Event
  // -----------------------------------------------------------------

  Widget _buildEvent(EventData event) {
    final dt = event.dateTime?.toDate();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FC.border.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FC.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FC.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: FC.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: FC.textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (dt != null)
                    Text(
                      DateFormat('EEE, d MMM · h:mm a').format(dt),
                      style: const TextStyle(color: FC.textLo, fontSize: 12),
                    ),
                  if ((event.location ?? '').isNotEmpty)
                    Text(
                      event.location!,
                      style: const TextStyle(color: FC.textLo, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _mi(String v, String label, Color color) =>
      PopupMenuItem(
        value: v,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
