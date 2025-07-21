import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:basefundi/movil/ventas/modificar_ventas_movil.dart';
import 'package:basefundi/movil/ventas/ventas_totales_movil.dart';
import 'package:basefundi/movil/ventas/realizar_venta_movil.dart';
import 'package:basefundi/desktop/ventas/modificar_ventas_desk.dart';
import 'package:basefundi/desktop/ventas/ventas_totales_desk.dart';
import 'package:basefundi/desktop/ventas/realizar_venta_desk.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/settings/transition.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool get isDesktop {
    if (kIsWeb) return true;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return true;
    }
    return false; // Android o iOS
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    children: [
                      const SizedBox(height: 12),
                      _buildBoton(
                        icono: Icons.receipt_long,
                        titulo: 'Ventas Totales',
                        subtitulo: 'Historial de ventas realizadas',
                        destino:
                            isDesktop
                                ? const VentasTotalesDeskScreen()
                                : const VentasTotalesScreen(),
                      ),
                      const SizedBox(height: 12),
                      _buildBoton(
                        icono: Icons.edit_note,
                        titulo: 'Modificar Ventas',
                        subtitulo: 'Editar ventas registradas',
                        destino:
                            isDesktop
                                ? const ModificarVentasDeskScreen()
                                : const ModificarVentasScreen(),
                      ),
                      const SizedBox(height: 12),
                      _buildBoton(
                        icono: Icons.shopping_cart,
                        titulo: 'Realizar Venta',
                        subtitulo: 'Registrar nueva venta',
                        destino:
                            isDesktop
                                ? const VentasDetalleDeskScreen()
                                : const VentasDetalleScreen(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoton({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
  }) {
    return InkWell(
      onTap: () {
        navigateWithTransition(
          context: context,
          destination: destino,
          transition: TransitionType.fade,
          replace: false,
        );
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
          leading: Icon(icono, color: const Color(0xFF2C3E50), size: 30),
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
          'Ventas',
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
