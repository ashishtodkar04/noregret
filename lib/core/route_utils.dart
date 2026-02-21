import 'package:flutter/material.dart';

/// A premium fade, subtle slide, and focus-scale transition.
/// Best used for high-importance screen shifts (e.g., Home to Stats).
PageRoute fadeRoute(Widget page) {
  return PageRouteBuilder(
    // 250ms is the sweet spot for responsiveness vs elegance
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic, 
        reverseCurve: Curves.easeInCubic,
      );

      // Animation 1: Subtle Opacity
      return FadeTransition(
        opacity: curvedAnimation,
        // Animation 2: Very tight upward slide (2% of screen height)
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02), 
            end: Offset.zero,
          ).animate(curvedAnimation),
          // Animation 3: Micro-scale for that "Pop" into focus
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );
}

/// A "Fast-Action" route for quick popups or settings.
/// No slide, just a pure instant fade.
PageRoute instantFade(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}