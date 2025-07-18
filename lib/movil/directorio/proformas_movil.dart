import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import 'package:basefundi/movil/directorio/proformas/proforma_ventas_movil.dart';
import 'package:basefundi/movil/directorio/proformas/proformas_guardadas_movil.dart';
import 'package:basefundi/movil/directorio/proformas/proforma_fundicion_movil.dart';
import 'package:basefundi/desktop/directorio/proforfun.dart'; // desktop version
import 'package:basefundi/desktop/directorio/profventas.dart';

class OpcionesProformasScreen extends StatelessWidget {
  const OpcionesProformasScreen({super.key});

  // Método para decidir qué pantalla abrir según plataforma para Proforma Fundición
  Widget _getProformaFundicionScreen() {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return const ProformaCompraScreenDesktop();
    } else {
      return const ProformaCompraScreen();
    }
  }

  // Método para decidir qué pantalla abrir según plataforma para Proforma Ventas (ejemplo)
  Widget _getProformaVentasScreen() {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return ProformaScreenDesktop(); // Si tienes versión desktop
    } else {
      return ProformaScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCard(
              context: context,
              title: 'Proforma Ventas',
              subtitle: 'Genera una proforma y guárdala',
              icon: Icons.add_circle_outline,
              destination: _getProformaVentasScreen(),
            ),
            const SizedBox(height: 12),
            _buildCard(
              context: context,
              title: 'Proforma Fundición',
              subtitle: 'Genera una proforma compra de hierro',
              icon: Icons.add_circle_outline,
              destination: _getProformaFundicionScreen(),
            ),
            const SizedBox(height: 12),
            _buildCard(
              context: context,
              title: 'Ver Proformas Guardadas',
              subtitle: 'Consulta todas las proformas registradas',
              icon: Icons.list_alt_outlined,
              destination: const ProformasGuardadasScreen(),
            ),
            const SizedBox(height: 12),
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
          'Opciones de Proformas',
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
