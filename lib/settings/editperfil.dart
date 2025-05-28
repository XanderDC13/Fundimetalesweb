import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _isLoading = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = _auth.currentUser;
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    if (_usuario == null) return;

    final doc =
        await _firestore
            .collection('usuarios_activos')
            .doc(_usuario!.uid)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      _nombreController.text = data['nombre'] ?? '';
      _emailController.text = _usuario!.email ?? '';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate() || _usuario == null) return;

    final nuevoNombre = _nombreController.text.trim();
    final nuevoEmail = _emailController.text.trim();
    final nuevaContrasena = _contrasenaController.text.trim();

    try {
      if (nuevoEmail != _usuario!.email) {
        await _usuario!.updateEmail(nuevoEmail);
      }

      if (nuevaContrasena.isNotEmpty) {
        await _usuario!.updatePassword(nuevaContrasena);
      }

      await _firestore
          .collection('usuarios_activos')
          .doc(_usuario!.uid)
          .update({
            'nombre': nuevoNombre,
            'email': nuevoEmail,
            if (nuevaContrasena.isNotEmpty) 'contrasena': nuevaContrasena,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al actualizar: ${e.code}';

      if (e.code == 'requires-recent-login') {
        mensaje =
            'Por seguridad, vuelve a iniciar sesión para cambiar esta información.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1E40AF)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: Color(0xFF1E40AF)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Editar Perfil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            children: [
                              TextFormField(
                                controller: _nombreController,
                                decoration: _inputDecoration(
                                  'Nombre',
                                  Icons.person,
                                ),
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Campo requerido'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDecoration(
                                  'Email',
                                  Icons.email,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Campo requerido';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contrasenaController,
                                decoration: _inputDecoration(
                                  'Nueva Contraseña (opcional)',
                                  Icons.lock,
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      value.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: _guardarCambios,
                                icon: const Icon(
                                  Icons.save,
                                  color: Color(0xFF1E40AF),
                                ),
                                label: const Text(
                                  'Guardar Cambios',
                                  style: TextStyle(color: Color(0xFF1E40AF)),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
