import 'package:basefundi/movil/directorio/clientes_movil.dart';
import 'package:basefundi/movil/directorio/proformas_movil.dart';
import 'package:basefundi/movil/directorio/proveedores_movil.dart';
import 'package:flutter/material.dart';

class DirectorioScreen extends StatelessWidget {
  const DirectorioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            // Tarjeta 1: Proformas
            _buildCard(
              context: context,
              title: 'Proformas',
              subtitle: 'Control de proformas e inventario',
              icon: Icons.receipt_long,
              destination: OpcionesProformasScreen(),
            ),

            const SizedBox(height: 12),
            // Tarjeta 2: Clientes
            _buildCard(
              context: context,
              title: 'Clientes',
              subtitle: 'Gestión y contactos de clientes',
              icon: Icons.receipt_long,
              destination: const ClientesScreen(),
            ),

            const SizedBox(height: 12),

            // Tarjeta 3: Proveedores
            _buildCard(
              context: context,
              title: 'Proveedores',
              subtitle: 'Lista de proveedores y suministros',
              icon: Icons.analytics,
              destination: const ProveedoresScreen(),
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
          'Directorio',
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
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
      ),
    );
  }
}
