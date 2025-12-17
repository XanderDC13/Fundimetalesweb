import 'package:basefundi/desktop/directorio/contactos_desk.dart';
import 'package:basefundi/desktop/directorio/pedidos_desk.dart';
import 'package:basefundi/desktop/directorio/proformas_desk.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DirectorioDeskScreen extends StatefulWidget {
  const DirectorioDeskScreen({super.key});

  @override
  State<DirectorioDeskScreen> createState() => _DirectorioDeskScreenState();
}

class _DirectorioDeskScreenState extends State<DirectorioDeskScreen>
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
                      'Directorio',
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
                          _buildCard(
                            context: context,
                            title: 'Proformas',
                            subtitle: 'Control de proformas e inventario',
                            icon: Icons.receipt_long,
                            destination: OpcionesProformasDeskScreen(),
                          ),

                          // ✅ SOLO MOSTRAR PEDIDOS SI NO ES VENDEDOR
                          if (rol != 'Vendedor') ...[
                            const SizedBox(height: 20),
                            _buildCard(
                              context: context,
                              title: 'Pedidos',
                              subtitle: 'Control de nuevos pedidos y envíos',
                              icon: Icons.assignment,
                              destination: PedidosDeskScreen(),
                            ),
                          ],

                          const SizedBox(height: 20),
                          _buildCard(
                            context: context,
                            title: 'Contactos',
                            subtitle:
                                'Gestión y contactos de clientes y proveedores',
                            icon: Icons.people_outline,
                            destination: const ContactosDeskScreen(),
                          ),
                          const SizedBox(height: 20),
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

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () {
        navegarConFade(context, destination);
      },
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
          leading: Icon(icon, color: const Color(0xFF2C3E50)),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFB0BEC5)),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ),
      ),
    );
  }
}
