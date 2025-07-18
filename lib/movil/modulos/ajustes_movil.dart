import 'package:basefundi/movil/ajustes/editperfil_movil.dart';
import 'package:basefundi/movil/ajustes/feedback_movil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SectionTitle(title: 'Perfil'),
                  _buildBoton(
                    icon: Icons.person,
                    titulo: 'Editar perfil',
                    subtitulo: 'Cambiar datos de usuario',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditarPerfilScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const SectionTitle(title: 'Soporte'),
                  _buildBoton(
                    icon: Icons.help_outline,
                    titulo: 'Centro de ayuda',
                    subtitulo: 'Consulta preguntas frecuentes',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: Icons.feedback,
                    titulo: 'Enviar feedback',
                    subtitulo: 'Opinión o sugerencias',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBoton(
                    icon: Icons.info_outline,
                    titulo: 'Versión de la app',
                    subtitulo: '1.0.0',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle(title: 'Cuenta'),
                  _buildBoton(
                    icon: Icons.logout,
                    titulo: 'Cerrar sesión',
                    subtitulo: 'Salir de la aplicación',
                    onTap: () => _cerrarSesion(context),
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
          'Configuración',
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
            vertical: 3,
          ),
          leading: Icon(icon, color: Color(0xFF2C3E50)),
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
