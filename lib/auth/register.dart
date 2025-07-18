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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  String _selectedRole = 'Empleado';
  String? _selectedSede;
  List<String> _listaSedes = [];
  bool _cargandoSedes = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _cargarSedes();
  }

  Future<void> _cargarSedes() async {
    try {
      final snapshot = await _firestore.collection('sedes').get();
      setState(() {
        _listaSedes =
            snapshot.docs.map((doc) => doc['nombre'] as String).toList()
              ..sort();
        _selectedSede = _listaSedes.isNotEmpty ? _listaSedes.first : null;
        _cargandoSedes = false;
      });
    } catch (e) {
      print('Error al cargar sedes: $e');
      setState(() {
        _cargandoSedes = false;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text;

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
              'sede': _selectedSede,
              'uid': userCredential.user!.uid,
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
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2F8), Color(0xFFD6EAF8), Color(0xFFB0D4F1)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '¡Nos alegra tenerte aquí!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Regístrate para comenzar',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                        ),
                      ],
                      decoration: _inputDecoration(
                        icon: Icons.person,
                        hint: 'Nombre',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
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
                        if (!value.contains('@')) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
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
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: _inputDecoration(
                        icon: Icons.badge,
                        hint: 'Rol',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Administrador',
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 'Empleado',
                          child: Text('Empleado'),
                        ),
                      ],
                      onChanged:
                          (value) => setState(() => _selectedRole = value!),
                    ),
                    const SizedBox(height: 20),
                    _cargandoSedes
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                          value: _selectedSede,
                          decoration: _inputDecoration(
                            icon: Icons.location_city,
                            hint: 'Sede',
                          ),
                          items:
                              _listaSedes
                                  .map(
                                    (sede) => DropdownMenuItem(
                                      value: sede,
                                      child: Text(sede),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _selectedSede = value),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Selecciona una sede'
                                      : null,
                        ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '¿Ya tienes cuenta? Inicia sesión',
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
    );
  }
}
