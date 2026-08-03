import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/chat_effects.dart';

/// Wraps a curve and clamps its output to [0.0, 1.0]. Needed for curves like
/// Curves.easeOutBack that intentionally overshoot past 1.0 for a bounce
/// effect — TweenSequence throws an assertion error if fed a value outside
/// that range, so we clamp it here while keeping the bounce feel.
class _ClampedCurve extends Curve {
  final Curve curve;
  const _ClampedCurve(this.curve);

  @override
  double transform(double t) => curve.transform(t).clamp(0.0, 1.0);
}

class ChatEffectOverlayWidget extends StatefulWidget {
  final ChatEffect effect;
  final VoidCallback onComplete;
  final Size screenSize;

  const ChatEffectOverlayWidget({
    super.key,
    required this.effect,
    required this.onComplete,
    required this.screenSize,
  });

  @override
  State<ChatEffectOverlayWidget> createState() =>
      _ChatEffectOverlayWidgetState();
}

class _ChatEffectOverlayWidgetState extends State<ChatEffectOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final EffectMotion _motion;
  late final double _startX;
  late final Animation<double> _posAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  bool _completedCalled = false;

  void _callCompleteOnce() {
    if (_completedCalled) return;
    _completedCalled = true;
    widget.onComplete();
  }

  @override
  void initState() {
    super.initState();
    _motion = widget.effect.motion ?? ChatEffectMatcher.randomMotion();
    final maxX = (widget.screenSize.width - widget.effect.size).clamp(
      0,
      double.infinity,
    );
    _startX = Random().nextDouble() * maxX;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    switch (_motion) {
      case EffectMotion.floatUp:
        _posAnim = Tween<double>(
          begin: widget.screenSize.height * 0.55,
          end: -widget.effect.size,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        _fadeAnim = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(_controller);
        _scaleAnim = Tween(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
        );
        break;

      case EffectMotion.fallDown:
        _posAnim = Tween<double>(
          begin: -widget.effect.size,
          end: widget.screenSize.height * 0.7,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
        _fadeAnim = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
        ]).animate(_controller);
        _scaleAnim = const AlwaysStoppedAnimation(1.0);
        break;

      case EffectMotion.burstOutward:
        _posAnim = Tween<double>(
          begin: widget.screenSize.height * 0.4,
          end: widget.screenSize.height * 0.4,
        ).animate(_controller);
        _fadeAnim = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
        ]).animate(_controller);
        _scaleAnim =
            TweenSequence([
              TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.3), weight: 40),
              TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
            ]).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const _ClampedCurve(
                  Curves.easeOutBack,
                ), // clamped — fixes the crash
              ),
            );
        break;

      case EffectMotion.custom:
        _posAnim =
            Tween<double>(
              begin: widget.screenSize.height * 0.48,
              end: widget.screenSize.height * 0.42,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            );
        _fadeAnim = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(_controller);
        _scaleAnim = Tween(begin: 0.9, end: 1.05).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
    }

    _controller.forward().whenComplete(_callCompleteOnce);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centerX = widget.screenSize.width / 2 - widget.effect.size / 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final left =
            (_motion == EffectMotion.burstOutward ||
                _motion == EffectMotion.custom)
            ? centerX
            : _startX;
        return Positioned(
          left: left,
          top: _posAnim.value,
          child: Opacity(
            opacity: _fadeAnim.value.clamp(0.0, 1.0),
            child: Transform.scale(scale: _scaleAnim.value, child: child),
          ),
        );
      },
      child: IgnorePointer(
        child: SizedBox(
          width: widget.effect.size,
          height: widget.effect.size,
          child: Lottie.asset(
            widget.effect.lottieAsset,
            fit: BoxFit.contain,
            repeat: false,
            errorBuilder: (context, error, stackTrace) {
              if (!_completedCalled) {
                _controller.stop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _callCompleteOnce();
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
