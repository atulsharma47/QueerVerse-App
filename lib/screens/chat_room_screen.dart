import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/feed/feed_app_bar.dart';
import '../utils/chat_effects.dart';
import '../widgets/chat/effect_overlay_widget.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ChatRoomScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String _chatId = ChatService.chatIdFor(widget.userId);

  final List<Widget> _activeEffects = [];
  int _effectIdCounter = 0;
  String? _lastSeenMessageId;
  final Set<String> _playedOnceEffects =
      {}; // resets if screen is closed/reopened

  void _maybeTriggerEffect(String text) {
    final effect = ChatEffectMatcher.findEffect(text, _playedOnceEffects);
    if (effect == null) return;

    final id = _effectIdCounter++;
    final key = ValueKey(id);
    final screenSize = MediaQuery.of(context).size;

    setState(() {
      _activeEffects.add(
        ChatEffectOverlayWidget(
          key: key,
          effect: effect,
          screenSize: screenSize,
          onComplete: () {
            if (!mounted) return;
            setState(() => _activeEffects.removeWhere((w) => w.key == key));
          },
        ),
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    _maybeTriggerEffect(text); // fire immediately for the sender
    await ChatService.sendMessage(widget.userId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatService.markRead(_chatId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: FC.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: ChatService.messagesStream(_chatId),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            '${snap.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: FC.primary),
                        );
                      }

                      final messages = snap.data!;
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Start the conversation',
                            style: TextStyle(color: FC.textMid),
                          ),
                        );
                      }

                      // Detect genuinely new incoming messages and fire an effect
                      final latest = messages.last;
                      if (latest.id != _lastSeenMessageId) {
                        final isNewIncoming =
                            _lastSeenMessageId != null &&
                            latest.senderId != currentUserId;
                        _lastSeenMessageId = latest.id;
                        if (isNewIncoming) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _maybeTriggerEffect(latest.text);
                          });
                        }
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          final isMe = m.senderId == currentUserId;
                          return _MessageBubble(
                            text: m.text,
                            time: m.timestamp != null
                                ? DateFormat(
                                    'hh:mm a',
                                  ).format(m.timestamp!.toDate())
                                : '',
                            isMe: isMe,
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            ),
            ..._activeEffects,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: FC.textHi),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [FC.primary, FC.accent]),
            ),
            child: Center(
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.userName,
              style: const TextStyle(
                color: FC.textHi,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: FC.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FC.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: FC.textHi),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: FC.textLo),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [FC.primary, FC.accent]),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [FC.primary, FC.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : FC.card,
          border: isMe
              ? null
              : Border.all(color: FC.border.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: FC.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
