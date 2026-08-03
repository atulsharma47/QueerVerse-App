import 'dart:ui';

import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

class SocialButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final double size;

  const SocialButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 68,
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? .94 : (_hover ? 1.05 : 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: _hover ? AppColors.glassLight : AppColors.glass,

              border: Border.all(
                color: _hover ? AppColors.primary : AppColors.border,
                width: 1.2,
              ),

              boxShadow: [
                if (_hover)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .20),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
              ],
            ),

            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onTap,
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: _hover ? 1.08 : 1,
                        child: widget.icon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
