import 'package:basefundi/desktop/ajustes/editperfil_desk.dart';
import 'package:basefundi/desktop/ajustes/feedback_desk.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class SettingsDeskScreen extends StatefulWidget {
  const SettingsDeskScreen({super.key});

  @override
  State<SettingsDeskScreen> createState() => _SettingsDeskScreenState();
}

class _SettingsDeskScreenState extends State<SettingsDeskScreen>
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
                      'Configuración',
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

          // ✅ CONTENIDO PRINCIPAL con Fade
          Expanded(
            child: Container(
              color: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ListView(
                    children: [
                      const SectionTitle(title: 'Perfil'),
                      _buildBoton(
                        icon: Icons.person,
                        titulo: 'Editar perfil',
                        subtitulo: 'Cambiar datos de usuario',
                        onTap: () {
                          _navegarConFade(
                            context,
                            const EditarPerfilDeskScreen(),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      const SectionTitle(title: 'Soporte'),
                      _buildBoton(
                        icon: Icons.help_outline,
                        titulo: 'Centro de ayuda',
                        subtitulo: 'Consulta preguntas frecuentes',
                        onTap: () {
                          // Implementar acción si quieres
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: Icons.person,
                        titulo: 'Editar perfil',
                        subtitulo: 'Cambiar datos de usuario',
                        onTap: () {
                          _navegarConFade(context, const FeedbackDeskScreen());
                        },
                      ),

                      const SizedBox(height: 20),
                      _buildBoton(
                        icon: Icons.info_outline,
                        titulo: 'Versión de la app',
                        subtitulo: '1.0.0',
                        onTap: () {
                          // Implementar acción si quieres
                        },
                      ),
                      const SizedBox(height: 32),
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
          leading: Icon(icon, color: const Color(0xFF2C3E50)),
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

// ---------- Reusable section title ----------
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }
}
