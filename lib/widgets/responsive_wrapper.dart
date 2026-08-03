import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Option B: Still shows a "phone-style" card on web, but bigger and
/// closer to filling the viewport (less obviously boxed-in than before).
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Android / iOS
    if (!kIsWeb) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Bigger max size, closer to full viewport on most laptop
              // screens, so it doesn't look like a tiny boxed card.
              const double maxPhoneWidth = 600;
              const double maxPhoneHeight = 1100;

              // Use more of the available space (98% instead of 95%).
              double phoneWidth = constraints.maxWidth * 0.98;
              double phoneHeight = constraints.maxHeight * 0.98;

              if (phoneWidth > maxPhoneWidth) {
                phoneWidth = maxPhoneWidth;
              }

              if (phoneHeight > maxPhoneHeight) {
                phoneHeight = maxPhoneHeight;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: phoneWidth,
                height: phoneHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF090B18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.55),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
