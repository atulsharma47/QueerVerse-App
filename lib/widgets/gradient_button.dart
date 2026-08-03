import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/app_colors.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool enabled;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.enabled = true,
    this.height = 58,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final canTap =
        widget.enabled && !widget.isLoading && widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
        onTapUp: canTap ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: canTap ? widget.onPressed : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? .97 : (_hover ? 1.02 : 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: widget.enabled
                  ? AppColors.primaryGradient
                  : LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade600],
                    ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.enabled
                      ? AppColors.primary.withValues(alpha: .35)
                      : Colors.black.withValues(alpha: .18),
                  blurRadius: _hover ? 34 : 26,
                  spreadRadius: 1,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: canTap ? widget.onPressed : null,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.text,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                letterSpacing: .2,
                              ),
                            ),

                            if (widget.icon != null) ...[
                              const SizedBox(width: 10),
                              Icon(widget.icon, color: Colors.white, size: 20),
                            ],
                          ],
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
