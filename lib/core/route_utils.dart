import 'package:flutter/material.dart';

/// A premium fade and subtle slide transition.
PageRoute fadeRoute(Widget page) {
  return PageRouteBuilder(
    // 300ms is standard, but 250ms with a curve often feels "faster" to users
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Productive Approach: Use a Curve to make the motion feel natural
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic, // Decelerates for a smooth finish
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02), // Reduced distance for a tighter feel
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}