import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../themes/app_colors.dart';

/// Full-width success celebration: a big cartoon character runs from the
/// right edge to the left edge, trailing a few floating hearts, then a
/// "Your post is live!" toast fades in.
///
/// IMPORTANT: place this as the LAST child of a Stack that lives inside
/// your screen's own body (not the root Navigator overlay). That way the
/// LayoutBuilder below measures the actual width of your phone-frame /
/// screen instead of the full browser window, and it always renders on
/// top of your other content because it's last in the Stack.
class PostSuccessOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const PostSuccessOverlay({super.key, required this.onDone});

  @override
  State<PostSuccessOverlay> createState() => _PostSuccessOverlayState();
}

class _PostSuccessOverlayState extends State<PostSuccessOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _runController;
  late final AnimationController _toastController;
  final List<double> _heartOffsets = List.generate(
    5,
    (i) => Random().nextDouble(),
  );

  @override
  void initState() {
    super.initState();

    _runController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _runController.forward();

    // Toast fades in once the character is roughly mid-screen.
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _toastController.forward();
    });

    // Everything's done -> tell the parent to close / pop.
    Future.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _runController.dispose();
    _toastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        const characterSize = 230.0;

        return IgnorePointer(
          child: Stack(
            children: [
              // Dim backdrop
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: .45)),
              ),

              // Floating hearts trailing behind the runner
              ...List.generate(_heartOffsets.length, (i) {
                return AnimatedBuilder(
                  animation: _runController,
                  builder: (context, child) {
                    final t = (_runController.value - i * 0.08).clamp(0.0, 1.0);
                    final x =
                        width -
                        (width + characterSize) * t +
                        characterSize * 0.4;
                    final wobble = sin((t * 6) + i) * 14;
                    return Positioned(
                      left: x,
                      top: height * (0.35 + _heartOffsets[i] * 0.2) + wobble,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0) * 0.9,
                        child: const Text('💗', style: TextStyle(fontSize: 22)),
                      ),
                    );
                  },
                );
              }),

              // The big runner character, right -> left
              AnimatedBuilder(
                animation: _runController,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_runController.value);
                  final left = width - (width + characterSize) * t;
                  return Positioned(
                    left: left,
                    top: height / 2 - characterSize / 2,
                    child: child!,
                  );
                },
                child: Image.asset(
                  'assets/images/runner_boy.png',
                  width: characterSize,
                  height: characterSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('🏃', style: TextStyle(fontSize: 140)),
                ),
              ),

              // "Your post is live!" toast
              Positioned(
                left: 24,
                right: 24,
                bottom: height * 0.28,
                child: FadeTransition(
                  opacity: _toastController,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _toastController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 22,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .45),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        'Your post is live! ✨',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
}
