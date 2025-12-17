import 'package:basefundi/desktop/inventario/kardex_lista.dart';
import 'package:basefundi/desktop/inventario/medidas_desk.dart';
import 'package:basefundi/desktop/inventario/productos_desk.dart';
import 'package:basefundi/desktop/personal/insumos/insumos_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:basefundi/services/navbar_desk.dart';

class InventarioDeskScreen extends StatefulWidget {
  const InventarioDeskScreen({super.key});

  @override
  State<InventarioDeskScreen> createState() => _InventarioDeskScreenState();
}

class _InventarioDeskScreenState extends State<InventarioDeskScreen>
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
                      'Inventario',
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
                            icon: LucideIcons.clipboardList,
                            titulo: 'Productos',
                            subtitulo: 'Listado completo',
                            onTap: () {
                              navegarConFade(
                                context,
                                const TotalInvDeskScreen(),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildBoton(
                            icon: LucideIcons.clipboardList,
                            titulo: 'Catálogo de Productos',
                            subtitulo: 'Listado completo',
                            onTap: () {
                              navegarConFade(
                                context,
                                const VisualizarCatalogoScreen(),
                              );
                            },
                          ),

                          // ✅ SOLO MOSTRAR ESTOS SI NO ES VENDEDOR
                          if (rol != 'Vendedor') ...[
                            const SizedBox(height: 20),
                            _buildBoton(
                              icon: Icons.inventory_2,
                              titulo: 'Insumos',
                              subtitulo: 'Solicitud de insumos',
                              onTap: () {
                                navegarConFade(
                                  context,
                                  const InsumosDeskScreen(),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildBoton(
                              icon: Icons.inventory_2,
                              titulo: 'Kardex',
                              subtitulo: 'Cantidades por referencia',
                              onTap: () {
                                navegarConFade(
                                  context,
                                  const KardexListScreen(),
                                );
                              },
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
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2C3E50)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0BEC5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
