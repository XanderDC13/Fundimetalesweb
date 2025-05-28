import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String _selectedRole = 'Empleado';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final pin = _pinController.text.trim();

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _firestore
            .collection('usuarios_pendientes')
            .doc(userCredential.user!.uid)
            .set({
              'nombre': name,
              'email': email,
              'rol': _selectedRole,
              'uid': userCredential.user!.uid,
              'pin': pin,
              'estado': 'pendiente',
              'fechaRegistro': FieldValue.serverTimestamp(),
            });

        await userCredential.user!.sendEmailVerification();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registro enviado para aprobación. Espera la verificación del administrador.',
            ),
          ),
        );

        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Error al registrar';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'Este correo electrónico ya está registrado';
        } else if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es demasiado débil';
        } else {
          errorMessage = 'Error: ${e.message}';
          print('FirebaseAuthException: ${e.code} - ${e.message}');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1E3A8A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('lib/assets/logoletters.png', height: 75),
                    const SizedBox(height: 20),
                    const Text(
                      'Registro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                        ),
                      ],
                      decoration: _inputDecoration(
                        icon: Icons.person,
                        hint: 'Nombre Completo',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        if (!RegExp(
                          r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
                        ).hasMatch(value)) {
                          return 'Solo letras y espacios';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Correo
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        icon: Icons.email,
                        hint: 'Correo electrónico',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu correo electrónico';
                        }
                        if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(value)) {
                          return 'Ingresa un correo válido';
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
                            color: Color(0xFF1E3A8A),
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa una contraseña';
                        }
                        if (value.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration.collapsed(
                          hintText: '',
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF1E3A8A),
                        ),
                        dropdownColor: Colors.white,
                        items: [
                          DropdownMenuItem(
                            value: 'Administrador',
                            child: Row(
                              children: const [
                                Icon(Icons.security, color: Color(0xFF1E3A8A)),
                                SizedBox(width: 10),
                                Text('Administrador'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Empleado',
                            child: Row(
                              children: const [
                                Icon(Icons.work, color: Color(0xFF1E3A8A)),
                                SizedBox(width: 10),
                                Text('Empleado'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona un rol';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botón de registro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      fillColor: Colors.white,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
