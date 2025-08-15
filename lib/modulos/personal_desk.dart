import 'package:basefundi/desktop/personal/empleados/empleados_registro_desk.dart';
import 'package:basefundi/desktop/personal/funciones/tareas_empleados_desk.dart';
import 'package:basefundi/desktop/personal/insumos/insumos_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class PersonalDeskScreen extends StatefulWidget {
  const PersonalDeskScreen({super.key});

  @override
  State<PersonalDeskScreen> createState() => _PersonalDeskScreenState();
}

class _PersonalDeskScreenState extends State<PersonalDeskScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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
                      'Gestión de Personal',
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
                      _buildCard(
                        context: context,
                        title: 'Empleados',
                        subtitle: 'Lista de empleados',
                        icon: Icons.group,
                        destination: const EmpleadosPendientesDeskScreen(),
                      ),

                      const SizedBox(height: 20),
                      _buildCard(
                        context: context,
                        title: 'Funciones empleados',
                        subtitle: 'Asignación de funciones',
                        icon: Icons.assignment,
                        destination: const FuncionesDeskScreen(),
                      ),
                      const SizedBox(height: 20),
                      _buildCard(
                        context: context,
                        title: 'Insumos',
                        subtitle: 'Solicitud de insumos',
                        icon: Icons.inventory_2,
                        destination: const InsumosDeskScreen(),
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

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () {
        navegarConFade(context, destination);
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
    );
  }
}
