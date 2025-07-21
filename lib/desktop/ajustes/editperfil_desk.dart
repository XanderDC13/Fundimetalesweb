import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class EditarPerfilDeskScreen extends StatefulWidget {
  const EditarPerfilDeskScreen({super.key});

  @override
  State<EditarPerfilDeskScreen> createState() => _EditarPerfilDeskScreenState();
}

class _EditarPerfilDeskScreenState extends State<EditarPerfilDeskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _isLoading = true;
  User? _usuario;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? sedeSeleccionada;
  List<String> listaSedes = [];
  bool _cargandoSedes = true;

  @override
  void initState() {
    super.initState();
    _usuario = _auth.currentUser;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await _cargarSedes();
    await _cargarDatosUsuario();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _cargarSedes() async {
    try {
      final snapshot = await _firestore.collection('sedes').get();
      listaSedes =
          snapshot.docs.map((doc) => doc['nombre'] as String).toList()..sort();
    } catch (e) {
      print('Error al cargar sedes: $e');
    } finally {
      setState(() {
        _cargandoSedes = false;
      });
    }
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
      sedeSeleccionada = data['sede'] ?? null;
    }
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
            'sede': sedeSeleccionada ?? '',
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
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA con Transform.translate
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Editar Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                        padding: const EdgeInsets.all(64),
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            children: [
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
                              _cargandoSedes
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: sedeSeleccionada,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Sede',
                                          prefixIcon: Icon(
                                            Icons.location_city,
                                            color: Color(0xFF2C3E50),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        items:
                                            listaSedes.map((sede) {
                                              return DropdownMenuItem(
                                                value: sede,
                                                child: Text(
                                                  sede,
                                                  style: const TextStyle(
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            sedeSeleccionada = value;
                                          });
                                        },
                                        validator:
                                            (value) =>
                                                value == null || value.isEmpty
                                                    ? 'Seleccione una sede'
                                                    : null,
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: _guardarCambios,
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Guardar Cambios',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4682B4),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
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
          ),
        ],
      ),
    );
  }
}
