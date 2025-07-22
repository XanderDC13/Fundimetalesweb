import 'package:basefundi/movil/personal/empleados/empleados_registro_movil.dart';
import 'package:basefundi/movil/personal/funciones/tareas_empleados_movil.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/movil/personal/insumos/insumos_movil.dart';

class PersonalScreen extends StatelessWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            // Tarjeta 1: Empleados
            _buildCard(
              context: context,
              title: 'Empleados',
              subtitle: 'Lista de empleados',
              icon: Icons.group,
              destination: const EmpleadosPendientesScreen(),
            ),

            const SizedBox(height: 12),

            // Tarjeta 2: Funciones empleados
            _buildCard(
              context: context,
              title: 'Funciones empleados',
              subtitle: 'Asignación de funciones',
              icon: Icons.assignment,
              destination: const FuncionesScreen(),
            ),

            const SizedBox(height: 12),

            // Tarjeta 3: Insumos
            _buildCard(
              context: context,
              title: 'Insumos',
              subtitle: 'Solicitud de insumos',
              icon: Icons.inventory_2,
              destination: const InsumosScreen(),
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
          'Gestión de Personal',
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
