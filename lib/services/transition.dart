import 'package:flutter/material.dart';

void navegarConFade(BuildContext context, Widget pantalla) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, animation, __) => pantalla,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 150),
    ),
  );
}
