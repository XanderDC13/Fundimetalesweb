import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/desktop/ventas/modificar_ventas_desk.dart';
import 'package:basefundi/desktop/ventas/realizar_venta_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VentasDeskScreen extends StatefulWidget {
  const VentasDeskScreen({super.key});

  @override
  State<VentasDeskScreen> createState() => _VentasDeskScreenState();
}

class _VentasDeskScreenState extends State<VentasDeskScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
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
                      'Ventas',
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: FutureBuilder<String>(
                    future:
                        _obtenerRolUsuario(), // ✅ AGREGAR ESTE FUTUREBUILDER
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final rol = snapshot.data ?? '';

                      return ListView(
                        children: [
                          _buildBoton(
                            icono: Icons.shopping_cart,
                            titulo: 'Realizar Venta',
                            subtitulo: 'Registrar nueva venta',
                            destino: const VentasDetalleDeskScreen(),
                          ),

                          // ✅ SOLO MOSTRAR MODIFICAR VENTAS SI NO ES VENDEDOR
                          if (rol != 'Vendedor') ...[
                            const SizedBox(height: 20),
                            _buildBoton(
                              icono: Icons.edit_note,
                              titulo: 'Modificar Ventas',
                              subtitulo: 'Editar ventas registradas',
                              destino: const ModificarVentaDeskScreen(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ AGREGAR ESTE MÉTODO AL FINAL DE LA CLASE
  Future<String> _obtenerRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user.uid)
            .get();

    if (doc.exists) {
      return doc.data()?['rol'] ?? '';
    }
    return '';
  }

  Widget _buildBoton({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
  }) {
    return InkWell(
      onTap: () => navegarConFade(context, destino),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Icon(icono, color: const Color(0xFF2C3E50)),
          title: Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            subtitulo,
            style: const TextStyle(color: Color(0xFFB0BEC5)),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ),
      ),
    );
  }
}
