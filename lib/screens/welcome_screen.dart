import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import '../themes/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _kenBurnsController; // slow zoom + drift
  late final AnimationController _ambientController; // glow pulse + stars

  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  late final Animation<Offset> _panelSlide;

  late final Animation<double> _createBtnFade;
  late final Animation<double> _emailBtnFade;
  late final Animation<double> _dividerFade;
  late final Animation<double> _socialFade;
  late final Animation<double> _loginRowFade;

  late final Animation<double> _kenBurnsScale;
  late final Animation<double> _kenBurnsDrift;
  late final Animation<double> _glowPulse;

  // Mouse-parallax offset (web/desktop only — stays at zero on touch
  // devices since there's no hover).
  Offset _pointerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _kenBurnsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _kenBurnsScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _kenBurnsController, curve: Curves.easeInOut),
    );
    _kenBurnsDrift = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _kenBurnsController, curve: Curves.easeInOut),
    );
    _glowPulse = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    _taglineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.55, curve: Curves.easeOut),
    );
    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.12, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _panelSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.22, 0.85, curve: Curves.easeOutBack),
          ),
        );

    _createBtnFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );
    _emailBtnFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.52, 0.80, curve: Curves.easeOut),
    );
    _dividerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
    );
    _socialFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.68, 0.92, curve: Curves.easeOut),
    );
    _loginRowFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _kenBurnsController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _handlePointerHover(PointerHoverEvent event, Size size) {
    final dx = (event.position.dx / size.width - 0.5) * 2;
    final dy = (event.position.dy / size.height - 0.5) * 2;
    setState(() {
      _pointerOffset = Offset(dx * 10, dy * 6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.width / 390).clamp(0.8, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFF05060D),
      body: MouseRegion(
        onHover: (e) => _handlePointerHover(e, size),
        onExit: (_) => setState(() => _pointerOffset = Offset.zero),
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// Ken Burns background: slow zoom + horizontal drift +
            /// mouse parallax, alignment biased down so the moon stays
            /// in frame above the panel.
            AnimatedBuilder(
              animation: _kenBurnsController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _kenBurnsDrift.value + _pointerOffset.dx,
                    _pointerOffset.dy,
                  ),
                  child: Transform.scale(
                    scale: _kenBurnsScale.value,
                    alignment: const Alignment(0, 0.55),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                "assets/images/welcome_bg.png",
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.55),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            /// Soft pulsing purple glow, centered roughly where the
            /// moon sits.
            AnimatedBuilder(
              animation: _glowPulse,
              builder: (context, _) {
                return IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -0.05),
                    child: Container(
                      width: size.width * 1.1,
                      height: size.width * 1.1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(
                              0xFF9B7BFF,
                            ).withOpacity(0.18 * _glowPulse.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            /// Twinkling star particles.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(size.width, size.height * 0.55),
                    painter: _TwinkleStarsPainter(
                      progress: _ambientController.value,
                    ),
                  );
                },
              ),
            ),

            /// Dark gradient overlay — keeps text readable.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.30),
                      const Color(0xFF0B0820).withOpacity(0.92),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            /// Foreground content.
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 44 * scale),

                        SlideTransition(
                          position: _logoSlide,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: Text(
                              "QueerVerse",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzel(
                                color: Colors.white,
                                fontSize: 36 * scale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: const Color(
                                      0xFFB79CFF,
                                    ).withOpacity(0.55),
                                    blurRadius: 28,
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10 * scale),

                        SlideTransition(
                          position: _taglineSlide,
                          child: FadeTransition(
                            opacity: _taglineFade,
                            child: Text(
                              "A universe where you can be you.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 15 * scale,
                                height: 1.6,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 22 * scale),

                        SlideTransition(
                          position: _panelSlide,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32 * scale),
                                topRight: Radius.circular(32 * scale),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.45),
                                  blurRadius: 40,
                                  offset: const Offset(0, -10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32 * scale),
                                topRight: Radius.circular(32 * scale),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 28,
                                  sigmaY: 28,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.fromLTRB(
                                    28 * scale,
                                    26 * scale,
                                    28 * scale,
                                    18 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(
                                          0xFF6C5CE7,
                                        ).withOpacity(0.10),
                                        const Color(
                                          0xFF1B1530,
                                        ).withOpacity(0.55),
                                      ],
                                    ),
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.white.withOpacity(0.22),
                                        width: 1.2,
                                      ),
                                      left: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                      right: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FadeTransition(
                                        opacity: _createBtnFade,
                                        child: _PrimaryButton(
                                          label: "Create Account",
                                          scale: scale,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              _buildSharedTransitionRoute(
                                                const SignupScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      SizedBox(height: 12 * scale),

                                      FadeTransition(
                                        opacity: _emailBtnFade,
                                        child: _SecondaryButton(
                                          label: "Continue with Email",
                                          scale: scale,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              _buildSharedTransitionRoute(
                                                const LoginScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      SizedBox(height: 18 * scale),

                                      FadeTransition(
                                        opacity: _dividerFade,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                color: Colors.white.withOpacity(
                                                  0.18,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 14 * scale,
                                              ),
                                              child: Text(
                                                "OR",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white
                                                      .withOpacity(0.55),
                                                  fontSize: 12 * scale,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.white.withOpacity(
                                                  0.18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: 18 * scale),

                                      FadeTransition(
                                        opacity: _socialFade,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _SocialButton(
                                              icon: Icons.g_mobiledata,
                                              scale: scale,
                                              semanticLabel:
                                                  "Continue with Google",
                                              onTap: () {},
                                            ),
                                            _SocialButton(
                                              icon: Icons.apple,
                                              scale: scale,
                                              semanticLabel:
                                                  "Continue with Apple",
                                              onTap: () {},
                                            ),
                                            _SocialButton(
                                              icon: Icons.email_outlined,
                                              scale: scale,
                                              semanticLabel:
                                                  "Continue with magic link",
                                              onTap: () {},
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: 16 * scale),

                                      FadeTransition(
                                        opacity: _loginRowFade,
                                        child: _LoginRow(
                                          scale: scale,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              _buildSharedTransitionRoute(
                                                const LoginScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route _buildSharedTransitionRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// Lightweight twinkling star field.
class _TwinkleStarsPainter extends CustomPainter {
  final double progress;
  static final List<Offset> _seeds = _generateSeeds(36);

  _TwinkleStarsPainter({required this.progress});

  static List<Offset> _generateSeeds(int count) {
    final rnd = Random(7);
    return List.generate(
      count,
      (_) => Offset(rnd.nextDouble(), rnd.nextDouble()),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < _seeds.length; i++) {
      final seed = _seeds[i];
      final phase = (i / _seeds.length);
      final opacity =
          (0.25 + 0.55 * (0.5 + 0.5 * sin((progress + phase) * 2 * pi))).clamp(
            0.0,
            1.0,
          );
      final radius = 0.6 + (i % 3) * 0.5;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(seed.dx * size.width, seed.dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TwinkleStarsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Primary "Create Account" button.
class _PrimaryButton extends StatefulWidget {
  final String label;
  final double scale;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.scale,
    required this.onPressed,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    lowerBound: 0.0,
    upperBound: 0.06,
  );
  bool _hovering = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final s = 1.0 - _controller.value;
            return Transform.scale(scale: s, child: child);
          },
          child: Semantics(
            button: true,
            label: widget.label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52 * widget.scale,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(_hovering ? 0.40 : 0.25),
                    blurRadius: _hovering ? 26 : 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFFB79CFF).withOpacity(0.18),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16.5 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary "Continue with Email" button.
class _SecondaryButton extends StatefulWidget {
  final String label;
  final double scale;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.label,
    required this.scale,
    required this.onPressed,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52 * widget.scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(_hovering ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(_hovering ? 0.5 : 0.28),
              ),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.10),
                        blurRadius: 18,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              widget.label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15.5 * widget.scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass circular social login "orb".
class _SocialButton extends StatefulWidget {
  final IconData icon;
  final double scale;
  final String semanticLabel;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.scale,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _tapController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _tapScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.85,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.85,
        end: 1.06,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.06,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
  ]).animate(_tapController);

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 50 * widget.scale;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _tapController.forward(from: 0);
          widget.onTap();
        },
        child: Semantics(
          button: true,
          label: widget.semanticLabel,
          child: AnimatedBuilder(
            animation: _tapScale,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _hovering ? -3 : 0),
                child: Transform.scale(scale: _tapScale.value, child: child),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_hovering ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(_hovering ? 0.42 : 0.2),
                ),
                boxShadow: _hovering
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.12),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 26 * widget.scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Already have an account? Log In" row.
class _LoginRow extends StatefulWidget {
  final double scale;
  final VoidCallback onTap;

  const _LoginRow({required this.scale, required this.onTap});

  @override
  State<_LoginRow> createState() => _LoginRowState();
}

class _LoginRowState extends State<_LoginRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13 * widget.scale,
          ),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Semantics(
              button: true,
              label: "Log in to your account",
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: GoogleFonts.poppins(
                  color: _hovering
                      ? AppColors.secondary.withOpacity(0.75)
                      : AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * widget.scale,
                ),
                child: const Text("Log In"),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
