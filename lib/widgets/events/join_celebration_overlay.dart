import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../themes/app_colors.dart';
import 'couple_join_animation.dart';

OverlayEntry? _joinOverlay;

/// Shows the celebration directly on top of the current screen.
///
/// No dialog.
/// No popup.
/// No card.
/// No black background.
///
/// Just an overlay that disappears automatically.
Future<void> showJoinCelebration(BuildContext context) async {
  if (_joinOverlay != null) {
    _joinOverlay!.remove();
    _joinOverlay = null;
  }

  final overlay = Overlay.of(context);

  _joinOverlay = OverlayEntry(builder: (_) => const _JoinCelebrationOverlay());

  overlay.insert(_joinOverlay!);

  await Future.delayed(const Duration(milliseconds: 6200));

  if (_joinOverlay != null) {
    _joinOverlay!.remove();
    _joinOverlay = null;
  }
}

class _JoinCelebrationOverlay extends StatefulWidget {
  const _JoinCelebrationOverlay();

  @override
  State<_JoinCelebrationOverlay> createState() =>
      _JoinCelebrationOverlayState();
}

class _JoinCelebrationOverlayState extends State<_JoinCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  final _animKey = GlobalKey<CoupleJoinAnimationState>();

  late final AnimationController _controller;

  late final Animation<double> _textOpacity;

  late final Animation<double> _textScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    _textScale = Tween<double>(
      begin: .7,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animKey.currentState?.play();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return IgnorePointer(
      ignoring: true,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // =========================
            // Couple Animation
            // =========================
            Positioned(
              left: 0,
              right: 0,
              top: screen.height * .22,
              child: CoupleJoinAnimation(
                key: _animKey,
                height: 320,
                characterHeight: 220,
              ),
            ),

            // =========================
            // Floating Text
            // =========================
            Positioned(
              left: 0,
              right: 0,
              top: screen.height * .64,
              child: FadeTransition(
                opacity: _textOpacity,
                child: ScaleTransition(
                  scale: _textScale,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) {
                          return AppColors.primaryGradient.createShader(rect);
                        },
                        child: Text(
                          "🎉 Event Joined!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: .5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Have an amazing time together 💜",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: .92),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // =========================
            // Soft Glow Behind Animation
            // =========================
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // =========================
            // Floating Sparkles
            // =========================
            Positioned(
              top: screen.height * .26,
              left: screen.width * .42,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFFD54F),
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: screen.height * .37,
              right: screen.width * .32,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .5, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
