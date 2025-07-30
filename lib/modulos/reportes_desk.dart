import 'package:basefundi/desktop/reportes/auditoria_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_compras_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_inv_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_transporte_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_ventas_desk.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportesDeskScreen extends StatefulWidget {
  const ReportesDeskScreen({super.key});

  @override
  State<ReportesDeskScreen> createState() => _ReportesDeskScreenState();
}

class _ReportesDeskScreenState extends State<ReportesDeskScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  void _navegarConFade(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => pantalla,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

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
                      'Reportes',
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

          // ✅ CONTENIDO principal con FadeTransition
          Expanded(
            child: Container(
              color: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ListView(
                    children: [
                      _buildBoton(
                        icon: LucideIcons.clipboardList,
                        titulo: 'Reporte de Inventario',
                        subtitulo: 'Detalle de productos',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const ReporteInventarioDeskScreen(),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.clipboardList,
                        titulo: 'Reporte de Ventas',
                        subtitulo: 'Historial de ventas',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const ReporteVentasDeskScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.clipboardList,
                        titulo: 'Reporte de Compras',
                        subtitulo: 'Compra de materia prima',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const ReporteComprasDeskScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.clipboardList,
                        titulo: 'Reporte de Transporte',
                        subtitulo: 'Tiempos y entregas',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const ReporteTransporteDeskScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.clipboardList,
                        titulo: 'Auditoría',
                        subtitulo: 'Ediciones y cambios en el sistema',
                        onTap: () {
                          _navegarConFade(context, const AuditoriaDeskScreen());
                        },
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

  Widget _buildBoton({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
          leading: Icon(icon, color: const Color(0xFF2C3E50), size: 30),
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
