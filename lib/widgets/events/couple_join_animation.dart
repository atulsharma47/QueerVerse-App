import 'package:flutter/material.dart';

/// Two real illustrated characters walk in from either side, meet in the
/// middle, hold hands (with a heart pop), pause, then walk off together.
///
/// Trigger with a GlobalKey<CoupleJoinAnimationState> and call `.play()`.
class CoupleJoinAnimation extends StatefulWidget {
  final VoidCallback? onFinished;
  final double height;
  final double characterHeight;

  const CoupleJoinAnimation({
    super.key,
    this.onFinished,
    this.height = 220,
    this.characterHeight = 150,
  });

  @override
  State<CoupleJoinAnimation> createState() => CoupleJoinAnimationState();
}

class CoupleJoinAnimationState extends State<CoupleJoinAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const double _meet = 0.38;
  static const double _holdEnd = 0.82;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500), // slower, deliberate
    );
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished?.call();
    });
  }

  /// Plays the walk-in → hold-hands → walk-off sequence from the start.
  void play() => _c.forward(from: 0);

  /// Resets back to the idle (off-screen) pose.
  void reset() => _c.value = 0;

  bool get isHolding => _c.value >= _meet && _c.value <= _holdEnd;
  bool get isFinished => _c.status == AnimationStatus.completed;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) => _buildScene(w),
          );
        },
      ),
    );
  }

  Widget _buildScene(double w) {
    final t = _c.value;
    final centerX = w / 2;
    final charH = widget.characterHeight;
    final charW = charH * 0.62;
    const baseY = 30.0;

    final holding = t >= _meet;

    final walkBounce = !holding ? (3 * (1 - ((t * 10) % 2 - 1).abs())) : 0;

    double posA, posB;
    if (t <= _meet) {
      final p = Curves.easeOutCubic.transform((t / _meet).clamp(0.0, 1.0));
      posA = _lerp(-charW, centerX - charW * 1.15, p);
      posB = _lerp(w + charW, centerX + charW * 0.15, p);
    } else if (t <= _holdEnd) {
      posA = centerX - charW * 0.85;
      posB = centerX + charW * 0.15;
    } else {
      final p = Curves.easeInCubic.transform(
        ((t - _holdEnd) / (1 - _holdEnd)).clamp(0.0, 1.0),
      );
      final shift = _lerp(0, w + charW * 2, p);
      posA = centerX - charW * 0.85 + shift;
      posB = centerX + charW * 0.15 + shift;
    }

    double meetBounce = 0;
    if (t > _meet && t < _meet + 0.06) {
      final p = ((t - _meet) / 0.06).clamp(0.0, 1.0);
      meetBounce = (p < 0.5 ? p * 2 : (1 - p) * 2) * 10;
    }

    final showHeart = t > _meet + 0.10 && t < _holdEnd;
    final heartT = showHeart
        ? ((t - _meet - 0.02) / (_holdEnd - _meet - 0.02)).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // character A — arrives from the left
        Positioned(
          left: posA,
          bottom: baseY + walkBounce - meetBounce,
          child: Transform.rotate(
            angle: !holding ? 0.01 : 0,
            child: Image.asset(
              'assets/images/events/boy_walk.png',
              height: charH,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // character B — arrives from the right, with the umbrella
        // character B — arrives from the right, with the umbrella
        Positioned(
          left: posB,
          bottom: baseY + walkBounce - meetBounce,
          child: Transform.flip(
            flipX: true,
            child: Transform.rotate(
              angle: !holding ? -0.01 : 0,
              child: Image.asset(
                'assets/images/events/boy_walk_umbrella.png',
                height: charH,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        if (showHeart)
          Positioned(
            left: centerX - 18,
            bottom:
                baseY + charH * 0.72 + Curves.easeOut.transform(heartT) * 60,
            child: Opacity(
              opacity: heartT.isNaN
                  ? 0.0
                  : (1.0 - heartT).clamp(0.0, 1.0).toDouble(),
              child: Transform.scale(
                scale: 0.3 + Curves.elasticOut.transform(heartT) * 1.4,
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFFF4FA3),
                  size: 58,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
