import 'package:basefundi/desktop/directorio/proformas/proforma_fundicion_desk.dart';
import 'package:basefundi/desktop/directorio/proformas/proforma_ventas_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/desktop/directorio/proformas/proforma_guardadas_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class OpcionesProformasDeskScreen extends StatefulWidget {
  const OpcionesProformasDeskScreen({super.key});

  @override
  State<OpcionesProformasDeskScreen> createState() =>
      _OpcionesProformasDeskScreenState();
}

class _OpcionesProformasDeskScreenState
    extends State<OpcionesProformasDeskScreen>
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

  Widget _getProformaFundicionScreen() {
    return ProformaFundicionDeskScreen();
  }

  Widget _getProformaVentasScreen() {
    return ProformaVentasDeskScreen();
  }

  Widget _getProformaGuardadasScreen() {
    return ProformasGuardadasDeskScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA
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
                      'Opciones de Proformas',
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

          // ✅ CONTENIDO PRINCIPAL
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
                        icono: Icons.add_circle_outline,
                        titulo: 'Proforma Ventas',
                        subtitulo: 'Genera una proforma y guárdala',
                        destino: _getProformaVentasScreen(),
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icono: Icons.add_circle_outline,
                        titulo: 'Proforma Fundición',
                        subtitulo: 'Genera una proforma compra de hierro',
                        destino: _getProformaFundicionScreen(),
                      ),
                      const SizedBox(height: 20),
                      _buildBoton(
                        icono: Icons.list_alt_outlined,
                        titulo: 'Ver Proformas Guardadas de Ventas',
                        subtitulo: 'Consulta todas las proformas registradas',
                        destino: _getProformaGuardadasScreen(),
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

  Widget _buildBoton({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
  }) {
    return InkWell(
      onTap: () => navegarConFade(context, destino),
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
          leading: Icon(icono, color: const Color(0xFF2C3E50)),
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
