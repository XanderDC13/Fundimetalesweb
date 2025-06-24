import 'package:basefundi/screens/inventarios/inventariogeneral.dart';
import 'package:basefundi/screens/inventarios/inventariopintura.dart';
import 'package:basefundi/screens/inventarios/totalinv.dart';
import 'package:basefundi/screens/inventarios/transporte.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/screens/inventarios/newinventario.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildBoton(
                    icon: LucideIcons.clipboardList,
                    titulo: 'Productos',
                    subtitulo: 'Listado completo',
                    onTap: () {
                      navigateWithTransition(
                        context: context,
                        destination: const TotalInvScreen(),
                        transition: TransitionType.fade,
                        replace: false,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: LucideIcons.flame,
                    titulo: 'Inventario en Fundición',
                    subtitulo: 'Registro de fundición',
                    onTap: () {
                      navigateWithTransition(
                        context: context,
                        destination: const InventarioFundicionScreen(),
                        transition: TransitionType.fade,
                        replace: false,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: LucideIcons.paintBucket,
                    titulo: 'Inventario en Pintura',
                    subtitulo: 'Registro de pintura',
                    onTap: () {
                      navigateWithTransition(
                        context: context,
                        destination: const InventarioPinturaScreen(),
                        transition: TransitionType.fade,
                        replace: false,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: LucideIcons.box,
                    titulo: 'Inventario General',
                    subtitulo: 'Suma final de productos',
                    onTap: () {
                      navigateWithTransition(
                        context: context,
                        destination: InventarioGeneralScreen(),
                        transition: TransitionType.fade,
                        replace: false,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: LucideIcons.car,
                    titulo: 'Transporte',
                    subtitulo: 'Tiempos de entrega',
                    onTap: () {
                      navigateWithTransition(
                        context: context,
                        destination: const ReporteTransporteFScreen(),
                        transition: TransitionType.fade,
                        replace: false,
                      );
                    },
                  ),
                ],
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
          'Inventario',
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
        elevation: 0,
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
