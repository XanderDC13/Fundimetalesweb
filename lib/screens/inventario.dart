import 'package:basefundi/screens/inventarios/inventariogeneral.dart';
import 'package:basefundi/screens/inventarios/inventariopintura.dart';
import 'package:basefundi/screens/inventarios/totalinv.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/screens/inventarios/newinventario.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    _buildCard(
                      icon: LucideIcons.clipboardList,
                      label: 'Productos',
                      onTap: () {
                        navigateWithTransition(
                          context: context,
                          destination: const TotalInvScreen(),
                          transition: TransitionType.fade,
                          replace: false,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      icon: LucideIcons.flame,
                      label: 'Inventario en Fundición',
                      onTap: () {
                        navigateWithTransition(
                          context: context,
                          destination: const InventarioFundicionScreen(),
                          transition: TransitionType.fade,
                          replace: false,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      icon: LucideIcons.paintBucket,
                      label: 'Inventario en Pintura',
                      onTap: () {
                        navigateWithTransition(
                          context: context,
                          destination: const InventarioPinturaScreen(),
                          transition: TransitionType.fade,
                          replace: false,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      icon: LucideIcons.box,
                      label: 'Inventario General',
                      onTap: () {
                        navigateWithTransition(
                          context: context,
                          destination: InventarioGeneralScreen(),
                          transition: TransitionType.fade,
                          replace: false,
                        );
                      },
                    ),
                  ],
                ),
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
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
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

  Widget _buildCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
