import 'package:basefundi/screens/personal/ingresopersonal.dart';
import 'package:basefundi/screens/personal/funciones.dart';
import 'package:flutter/material.dart';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmpleadosPendientesScreen(),
                    ),
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
                    leading: const Icon(Icons.group, color: Color(0xFF2C3E50)),
                    title: const Text(
                      'Empleados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text(
                      'Lista de empleados',
                      style: TextStyle(color: Color(0xFFB0BEC5)),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tarjeta 2: Funciones empleados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FuncionesScreen(),
                    ),
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
                    leading: const Icon(
                      Icons.assignment,
                      color: Color(0xFF2C3E50),
                    ),
                    title: const Text(
                      'Funciones empleados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text(
                      'Asignación de funciones',
                      style: TextStyle(color: Color(0xFFB0BEC5)),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                    ),
                  ),
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
}
