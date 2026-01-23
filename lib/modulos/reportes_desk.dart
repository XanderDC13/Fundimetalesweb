import 'package:basefundi/desktop/reportes/auditoria_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_compras_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_documentos_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_fundicion_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_proformas_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_ventas_desk.dart';
import 'package:basefundi/desktop/reportes/reportes%20inventarios/inventario_procesos_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportesDeskScreen extends StatefulWidget {
  const ReportesDeskScreen({super.key});

  @override
  State<ReportesDeskScreen> createState() => _ReportesDeskScreenState();
}

class _ReportesDeskScreenState extends State<ReportesDeskScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  String? _rol;
  String? _sede;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            _rol = data?['rol'];
            _sede = data?['sede'];
            _isLoading = false;
          });
          _controller.forward();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _controller.forward();
    }
  }

  /// Verifica si el usuario puede ver un reporte específico
  bool _puedeVerReporte(String nombreReporte) {
    if (_rol == null || _sede == null) return false;

    // Gerente puede ver todos los reportes
    if (_rol == "Gerente") return true;

    // Administrador General de Tulcán puede ver todos los reportes
    if (_rol == "Administrador General" && _sede == "Tulcán") {
      return true;
    }

    // Administradores de Quito/Guayaquil solo pueden ver Reporte Ventas
    if (_rol == "Administrador General" &&
        (_sede == "Quito" || _sede == "Guayaquil")) {
      return nombreReporte == "Reporte Ventas";
    }

    // Vendedor puede ver Reporte Ventas y Reporte Proformas
    if (_rol == "Vendedor") {
      return nombreReporte == "Reporte Ventas" ||
          nombreReporte == "Reporte Proformas";
    }

    return false;
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
          // Cabecera
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
                      'Reportes',
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

          // Contenido principal
          Expanded(
            child: Container(
              color: Colors.white,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: ListView(
                            children: [
                              // Reporte Ventas (todos los roles permitidos)
                              if (_puedeVerReporte("Reporte Ventas")) ...[
                                _buildBoton(
                                  icon: LucideIcons.clipboardList,
                                  titulo: 'Reporte Ventas',
                                  subtitulo: 'Historial de ventas',
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      const ReporteVentasDeskScreen(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Reporte Inventario (solo Gerente y Admin Tulcán)
                              if (_puedeVerReporte("Reporte Inventario")) ...[
                                _buildBoton(
                                  icon: LucideIcons.clipboardList,
                                  titulo: 'Reporte Inventario',
                                  subtitulo: 'Detalle de productos',
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      const InventarioProcesoDeskScreen(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Reporte Cotizaciones (solo Gerente y Admin Tulcán)
                              if (_puedeVerReporte("Reporte Cotizaciones")) ...[
                                _buildBoton(
                                  icon: LucideIcons.clipboardList,
                                  titulo: 'Reporte Cotizaciones',
                                  subtitulo:
                                      'Historial de proformas de cotización',
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      const ReporteProformasVentasDeskScreen(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Reporte Proformas/Ordenes (solo Gerente y Admin Tulcán)
                              if (_puedeVerReporte("Reporte Proformas")) ...[
                                _buildBoton(
                                  icon: LucideIcons.clipboardList,
                                  titulo: 'Reporte Proformas / Ordenes',
                                  subtitulo: 'Proformas y Ordenes de despacho',
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      const ReporteDocumentosDeskScreen(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Reporte Materia Prima (solo Gerente y Admin Tulcán)
                              if (_puedeVerReporte(
                                "Reporte Materia Prima",
                              )) ...[
                                _buildBoton(
                                  icon: LucideIcons.clipboardList,
                                  titulo: 'Reporte Materia Prima',
                                  subtitulo: 'Compra de materia prima',
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      const ReporteComprasDeskScreen(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              if (_puedeVerReporte("Reporte Fundición")) ...[
                                _buildBoton(
                                  icon: LucideIcons.clipboardList,
                                  titulo: 'Reporte Fundición',
                                  subtitulo: 'Tareas asignadas y completadas',
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      const ReportePedidosDeskScreen(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Auditoría (solo Gerente y Admin Tulcán)
                              if (_puedeVerReporte("Auditoría"))
                                _buildBoton(
                                  icon: LucideIcons.clipboardList,
                                  titulo: 'Auditoría',
                                  subtitulo:
                                      'Ediciones y cambios en el sistema',
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      const AuditoriaDeskScreen(),
                                    );
                                  },
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
          leading: Icon(icon, color: const Color(0xFF2C3E50), size: 30),
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
