import 'package:basefundi/desktop/administracion/cajaquito.dart';
import 'package:basefundi/desktop/administracion/cxc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/transition.dart';

class AdministracionDeskScreen extends StatefulWidget {
  const AdministracionDeskScreen({super.key});

  @override
  State<AdministracionDeskScreen> createState() =>
      _AdministracionDeskScreenState();
}

class _AdministracionDeskScreenState extends State<AdministracionDeskScreen>
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
          // ================= HEADER =================
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
                      'Administración',
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

          // ================= CONTENIDO =================
          Expanded(
            child: Container(
              color: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ListView(
                    children: [
                      _buildBoton(
                        icon: Icons.account_balance_wallet,
                        titulo: 'CxC',
                        subtitulo: 'Cuentas por cobrar',
                        onTap: () {
                          navegarConFade(context, const CxcScreen());
                        },
                      ),

                      _buildBoton(
                        icon: Icons.account_balance_wallet,
                        titulo: 'Caja',
                        subtitulo: 'Caja Quito y Guayaquil',
                        onTap: () async {
                          // Verificar si el usuario tiene rol de Gerente
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final userDoc =
                                await FirebaseFirestore.instance
                                    .collection('usuarios_activos')
                                    .doc(user.uid)
                                    .get();

                            if (userDoc.exists) {
                              final rol = userDoc['rol'] ?? '';
                              if (rol.toLowerCase() == 'gerente') {
                                navegarConFade(context, const CajaScreen());
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Acceso denegado. Solo Gerentes pueden acceder.',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      /*
_buildBoton(
  icon: Icons.account_balance_wallet,
  titulo: 'CxC',
  subtitulo: 'Cuentas por cobrar',
  onTap: () {
    // Solo Gerente podrá acceder a esta pantalla
    navegarConFade(context, const CxcScreen());
  },
),
*/
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

  // ================= BOTÓN =================
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

// ================= SECTION TITLE =================
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
