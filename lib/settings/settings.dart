import 'package:basefundi/settings/editperfil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(
      context,
    ).pushReplacementNamed('/login'); // Cambia la ruta según tu app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Container(
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Configuración',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de configuraciones
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const SectionTitle(title: 'Perfil'),
                  SettingsTile(
                    icon: Icons.person,
                    title: 'Editar perfil',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditarPerfilScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Soporte'),
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Centro de ayuda',
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Icons.feedback,
                    title: 'Enviar feedback',
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Versión de la app',
                    trailing: const Text(
                      '1.0.0',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 30),
                  const SectionTitle(title: 'Cuenta'),
                  SettingsTile(
                    icon: Icons.logout,
                    title: 'Cerrar sesión',
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
}

// ---------- Widgets reutilizables ----------

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
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFC0C0C0),
          child: Icon(icon, color: const Color(0xFF1E3A8A)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
