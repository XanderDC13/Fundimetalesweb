import 'package:basefundi/screens/reportes/reporteinv.dart';
import 'package:basefundi/screens/reportes/reportetransporte.dart';
import 'package:basefundi/screens/reportes/reporteventas.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(child: _buildHeader()),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  _buildBoton(
                    icon: LucideIcons.clipboardList,
                    titulo: 'Reporte de Inventario',
                    subtitulo: 'Detalle de productos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReporteInventarioScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: LucideIcons.barChart2,
                    titulo: 'Reporte de Ventas',
                    subtitulo: 'Historial de ventas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReporteVentasScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: LucideIcons.truck,
                    titulo: 'Reporte de Transporte',
                    subtitulo: 'Tiempos y entregas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReporteTransporteScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
          'Reportes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        elevation: 0, // sin sombra
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Icon(icon, color: Color(0xFF2C3E50), size: 30),
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
