import 'package:basefundi/desktop/directorio/proformas/documentos_desk.dart';
import 'package:basefundi/desktop/directorio/proformas/proforma_anticipo_desk.dart';
import 'package:basefundi/desktop/directorio/proformas/proforma_fundicion_desk.dart';
import 'package:basefundi/desktop/directorio/proformas/proforma_ventas_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/services/navbar_desk.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OpcionesProformasDeskScreen extends StatefulWidget {
  const OpcionesProformasDeskScreen({super.key});

  @override
  State<OpcionesProformasDeskScreen> createState() =>
      _OpcionesProformasDeskScreenState();
}

class _OpcionesProformasDeskScreenState
    extends State<OpcionesProformasDeskScreen>
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

  // ----------------------------
  // OBTENER ROL DEL USUARIO
  // ----------------------------
  Future<String> _obtenerRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user.uid)
            .get();

    return doc.data()?['rol'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // 🔵 HEADER
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Opciones de Proformas',
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

          // 🔵 CONTENIDO CON ROL
          Expanded(
            child: Container(
              color: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: FutureBuilder<String>(
                  future: _obtenerRolUsuario(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rol = snapshot.data ?? '';

                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: ListView(
                        children: [
                          // 👉 SIEMPRE SE MUESTRA
                          _buildBoton(
                            icono: Icons.add_circle_outline,
                            titulo: 'Proforma / Ordenes',
                            subtitulo: 'Genera proformas y ordenes de despacho',
                            destino: ProformaOrdenDespachoDeskScreen(),
                          ),

                          const SizedBox(height: 20),

                          // 👉 SOLO SI NO ES VENDEDOR
                          if (rol != 'Vendedor') ...[
                            _buildBoton(
                              icono: Icons.add_circle_outline,
                              titulo: 'Proforma Cotización',
                              subtitulo:
                                  'Genera proformas de cotización de ventas',
                              destino: ProformaVentasDeskScreen(),
                            ),
                            const SizedBox(height: 20),

                            _buildBoton(
                              icono: Icons.add_circle_outline,
                              titulo: 'Proforma Materia Prima',
                              subtitulo:
                                  'Genera proforma compra de materia prima',
                              destino: ProformaFundicionDeskScreen(),
                            ),
                            const SizedBox(height: 20),

                            _buildBoton(
                              icono: Icons.add_circle_outline,
                              titulo: 'Proforma Anticipos',
                              subtitulo:
                                  'Genera proforma de anticipos a usuarios',
                              destino: AnticiposDeskScreen(),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 BOTÓN REUTILIZABLE
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
