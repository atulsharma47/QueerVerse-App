import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../themes/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/events/join_celebration_overlay.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _busy = false;

  String _formatDate(EventModel e) {
    if (e.eventDate == null) return '';
    return DateFormat('dd MMM yyyy • h:mm a').format(e.eventDate!.toDate());
  }

  Future<void> _toggleJoin(EventModel event) async {
    setState(() => _busy = true);

    final joined = await EventService.toggleJoin(event.id, event.joinedUsers);

    if (!mounted) return;

    setState(() => _busy = false);

    if (joined) {
      showJoinCelebration(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: StreamBuilder<EventModel?>(
            stream: EventService.streamEvent(widget.eventId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final event = snapshot.data;
              if (event == null) {
                return Center(
                  child: Text(
                    'This event no longer exists.',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                );
              }

              final isJoined = event.isJoinedBy(currentUserId);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 100, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ShaderMask(
                                  shaderCallback: (rect) => AppColors
                                      .primaryGradient
                                      .createShader(rect),
                                  child: Text(
                                    event.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Event',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _detailRow(
                            Icons.location_on_outlined,
                            event.location,
                          ),
                          const SizedBox(height: 8),
                          _detailRow(
                            Icons.calendar_month_outlined,
                            _formatDate(event),
                          ),
                          const SizedBox(height: 8),
                          _detailRow(
                            Icons.people_alt_outlined,
                            'Participants: ${event.participantCount}',
                          ),
                          Divider(height: 32, color: AppColors.divider),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.surface,
                                backgroundImage: event.createdByImage.isNotEmpty
                                    ? NetworkImage(event.createdByImage)
                                    : null,
                                child: event.createdByImage.isEmpty
                                    ? Text(
                                        event.createdByName.isNotEmpty
                                            ? event.createdByName[0]
                                                  .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Created by',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.hint,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    event.createdByName,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Divider(height: 32, color: AppColors.divider),
                          Text(
                            'About this event',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 14.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Participants (${event.participantCount})',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ParticipantsRow(uids: event.joinedUsers),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: isJoined ? 'Leave Event' : 'Join Event',
                            icon: isJoined
                                ? Icons.logout_rounded
                                : Icons.favorite_border,
                            isLoading: _busy,
                            onPressed: () => _toggleJoin(event),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticipantsRow extends StatelessWidget {
  final List<String> uids;
  const _ParticipantsRow({required this.uids});

  @override
  Widget build(BuildContext context) {
    final shown = uids.take(6).toList();
    final overflow = uids.length - shown.length;

    return FutureBuilder<List<UserModel?>>(
      future: Future.wait(shown.map(UserService.fetchUser)),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];

        return SizedBox(
          height: 44,
          child: Stack(
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 30.0,
                  child: _avatar(i < users.length ? users[i] : null),
                ),
              if (overflow > 0)
                Positioned(
                  left: shown.length * 30.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$overflow',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatar(UserModel? user) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.background, width: 2),
        image: (user != null && user.profileImage.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(user.profileImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: (user == null || user.profileImage.isEmpty)
          ? Text(
              (user?.name.isNotEmpty ?? false)
                  ? user!.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            )
          : null,
    );
  }
}
