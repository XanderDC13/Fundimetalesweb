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
  User? _usuario;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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

  Widget _inputCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2C3E50)),
        title: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: label,
            border: InputBorder.none,
            isDense: true,
          ),
          validator: validator,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            children: [
                              const SizedBox(height: 20),
                              _inputCard(
                                icon: Icons.person,
                                label: 'Nombre',
                                controller: _nombreController,
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Campo requerido'
                                            : null,
                              ),
                              _inputCard(
                                icon: Icons.email,
                                label: 'Email',
                                controller: _emailController,
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
                              _inputCard(
                                icon: Icons.lock,
                                label: 'Nueva Contraseña (opcional)',
                                controller: _contrasenaController,
                                obscure: true,
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
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                                label: const Text(
                                  'Guardar Cambios',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4682B4),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Center(
        child: Text(
          'Editar Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
