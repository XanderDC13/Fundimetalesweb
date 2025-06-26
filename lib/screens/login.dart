import 'package:basefundi/screens/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/screens/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = await AuthService().signInWithEmailAndPassword(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          final doc =
              await FirebaseFirestore.instance
                  .collection('usuarios_activos')
                  .doc(user.uid)
                  .get();

          if (doc.exists) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else {
            await FirebaseAuth.instance.signOut();
            setState(() {
              _errorMessage = 'Tu cuenta está en proceso de verificación.';
            });
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'Error al iniciar sesión.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF2F8), // parte superior más clara
              Color(0xFFD6EAF8), // tono base
              Color(0xFFB0D4F1), // parte inferior un poco más viva
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen = constraints.maxWidth > 800;

            return Row(
              children: [
                if (isWideScreen)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Sistema de Gestión Fundimetales',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Bienvenido',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Inicia sesión para continuar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Correo
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: _inputDecoration(
                                      icon: Icons.person,
                                      hint: 'Correo electrónico',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ingresa tu correo';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Contraseña
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: _inputDecoration(
                                      icon: Icons.lock,
                                      hint: 'Contraseña',
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: const Color(0xFF4682B4),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ingresa tu contraseña';
                                      }
                                      if (value.length < 6) {
                                        return 'Mínimo 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 20),
                                  if (_errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4682B4,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Ingresar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: const Text(
                                      '¿No tienes cuenta? Regístrate',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF4682B4)),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }
}
