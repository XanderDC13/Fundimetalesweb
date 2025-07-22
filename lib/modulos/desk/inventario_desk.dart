import 'package:basefundi/desktop/inventario/inventario_fundicion_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_general_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_pintura_desk.dart';
import 'package:basefundi/desktop/inventario/productos_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_transporte_desk.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class InventarioDeskScreen extends StatefulWidget {
  const InventarioDeskScreen({super.key});

  @override
  State<InventarioDeskScreen> createState() => _InventarioDeskScreenState();
}

class _InventarioDeskScreenState extends State<InventarioDeskScreen>
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
          // ✅ CABECERA CON Transform.translate
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

          // ✅ CONTENIDO PRINCIPAL CON FADE
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
                        titulo: 'Productos',
                        subtitulo: 'Listado completo',
                        onTap: () {
                          _navegarConFade(context, const TotalInvDeskScreen());
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.flame,
                        titulo: 'Inventario en Fundición',
                        subtitulo: 'Registro de fundición',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const InventarioFundicionDeskScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.paintBucket,
                        titulo: 'Inventario en Pintura',
                        subtitulo: 'Registro de pintura',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const InventarioPinturaDeskScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.box,
                        titulo: 'Inventario General',
                        subtitulo: 'Suma final de productos',
                        onTap: () {
                          _navegarConFade(
                            context,
                            InventarioGeneralDeskScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: LucideIcons.car,
                        titulo: 'Transporte',
                        subtitulo: 'Tiempos de entrega',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const ReporteTransporteDeskScreen(),
                          );
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
