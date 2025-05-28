import 'package:flutter/material.dart';

enum TransitionType { fade, slide, scale }

void navigateWithTransition({
  required BuildContext context,
  required Widget destination,
  TransitionType transition = TransitionType.fade,
  Duration duration = const Duration(milliseconds: 200),
  bool replace = true,
}) {
  PageRouteBuilder route = PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => destination,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transition) {
        case TransitionType.slide:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        case TransitionType.scale:
          return ScaleTransition(scale: animation, child: child);
        case TransitionType.fade:
          return FadeTransition(opacity: animation, child: child);
      }
    },
  );

  if (replace) {
    Navigator.pushReplacement(context, route);
  } else {
    Navigator.push(context, route);
  }
}
