import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Big central heart + smaller hearts bursting outward.
/// Trigger via a GlobalKey<HeartBurstOverlayState> and call .burst().
class HeartBurstOverlay extends StatefulWidget {
  const HeartBurstOverlay({super.key});

  @override
  State<HeartBurstOverlay> createState() => HeartBurstOverlayState();
}

class HeartBurstOverlayState extends State<HeartBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final _rand = math.Random();
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  void burst() {
    _particles.clear();
    for (int i = 0; i < 10; i++) {
      _particles.add(
        _Particle(
          angle: _rand.nextDouble() * math.pi * 2,
          distance: 60 + _rand.nextDouble() * 120,
          size: 14 + _rand.nextDouble() * 14,
          delay: _rand.nextDouble() * 0.3,
        ),
      );
    }
    setState(() => _active = true);
    _ctrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _active = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.4 + Curves.easeOutBack.transform(t) * 1.4,
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFEC4899),
                    size: 140,
                  ),
                ),
              ),
              ..._particles.map((p) {
                final localT = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
                final dx = math.cos(p.angle) * p.distance * localT;
                final dy =
                    math.sin(p.angle) * p.distance * localT - (localT * 40);
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Opacity(
                    opacity: (1 - localT),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.pinkAccent,
                      size: p.size,
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

class _Particle {
  final double angle, distance, size, delay;
  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}
