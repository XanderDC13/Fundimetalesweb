import 'dart:async';
import 'package:flutter/material.dart';
import 'package:basefundi/screens/login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _imageController;
  late Animation<Offset> _imageAnimation;

  @override
  void initState() {
    super.initState();

    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _imageAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_imageController);

    _imageController.forward();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double logoSize = screenWidth < 600 ? 200 : 300;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo con degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E3A8A), Color(0xFFC0C0C0)],
              ),
            ),
          ),

          // Logo con animación y tamaño adaptable
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SlideTransition(
                position: _imageAnimation,
                child: Transform(
                  alignment: Alignment.center,
                  transform:
                      Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(0.1)
                        ..rotateY(0.1),
                  child: Image.asset(
                    'lib/assets/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
