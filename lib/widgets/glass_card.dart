import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:queerverse/themes/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin,
    this.borderRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(borderRadius),

              // Premium glass border
              border: Border.all(
                color: Colors.white.withValues(alpha: .12),
                width: 1.2,
              ),

              boxShadow: [
                // Purple ambient glow
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .12),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),

                // Lift the card off the background
                BoxShadow(
                  color: Colors.black.withValues(alpha: .35),
                  blurRadius: 35,
                  offset: const Offset(0, 12),
                ),
              ],

              // Very subtle highlight
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .05),
                  Colors.white.withValues(alpha: .015),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
