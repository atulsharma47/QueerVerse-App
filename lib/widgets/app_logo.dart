import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final String? subtitle;
  final TextAlign textAlign;

  const AppLogo({
    super.key,
    this.fontSize = 40,
    this.subtitle,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "QueerVerse",
          textAlign: textAlign,
          style: GoogleFonts.cinzel(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: AppColors.primary.withValues(alpha: .35),
                blurRadius: 18,
              ),
            ],
          ),
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 12),

          Text(
            subtitle!,
            textAlign: textAlign,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
