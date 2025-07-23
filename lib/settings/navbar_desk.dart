import 'package:basefundi/auth/login.dart';
import 'package:basefundi/desktop/ajustes/editperfil_desk.dart';
import 'package:basefundi/desktop/ajustes/feedback_desk.dart';
import 'package:basefundi/desktop/dashboard_desk.dart';
import 'package:basefundi/desktop/directorio/clientes_desk.dart';
import 'package:basefundi/desktop/directorio/proformas_desk.dart';
import 'package:basefundi/desktop/directorio/proveedores_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_fundicion_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_general_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_pintura_desk.dart';
import 'package:basefundi/desktop/inventario/productos_desk.dart';
import 'package:basefundi/desktop/inventario/transporte_desk.dart';
import 'package:basefundi/desktop/personal/empleados/empleados_registro_desk.dart';
import 'package:basefundi/desktop/personal/funciones/tareas_empleados_desk.dart';
import 'package:basefundi/desktop/personal/insumos/insumos_desk.dart';
import 'package:basefundi/desktop/reportes/auditoria_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_inv_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_transporte_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_ventas_desk.dart';
import 'package:basefundi/desktop/ventas/modificar_ventas_desk.dart';
import 'package:basefundi/desktop/ventas/realizar_venta_desk.dart';
import 'package:basefundi/desktop/ventas/ventas_totales_desk.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainDeskLayout extends StatefulWidget {
  final Widget child;

  const MainDeskLayout({super.key, required this.child});

  @override
  State<MainDeskLayout> createState() => _MainDeskLayoutState();
}

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

class _MainDeskLayoutState extends State<MainDeskLayout> {
  String? _expandedMenu;

  void _toggleMenu(String menu) {
    setState(() {
      if (_expandedMenu == menu) {
        _expandedMenu = null;
      } else {
        _expandedMenu = menu;
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // BARRA LATERAL
          Container(
            width: 250,
            color: const Color(0xFF2C3E50),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Fundimetales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: ListView(
                    children: [
                      _buildMainItem(
                        icon: Icons.home,
                        title: 'Inicio',
                        onTap: () {
                          _navegarConFade(context, const DashboardDeskScreen());
                        },
                      ),
                      _buildExpandableItem(
                        icon: Icons.shopping_cart,
                        title: 'Ventas',
                        menuKey: 'ventas',
                        subItems: [
                          _buildSubItem(
                            label: 'Ventas Totales',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const VentasTotalesDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Modificar Ventas',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const ModificarVentaDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Realizar Venta',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const VentasDetalleDeskScreen(),
                              );
                            },
                          ),
                        ],
                      ),

                      _buildExpandableItem(
                        icon: Icons.inventory,
                        title: 'Inventario',
                        menuKey: 'inventario',
                        subItems: [
                          _buildSubItem(
                            label: 'Productos',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const TotalInvDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'General',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const InventarioGeneralDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Fundición',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const InventarioFundicionDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Pintura',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const InventarioPinturaDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Transporte',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const TransporteDeskScreen(),
                              );
                            },
                          ),
                        ],
                      ),
                      _buildExpandableItem(
                        icon: Icons.people,
                        title: 'Personal',
                        menuKey: 'personal',
                        subItems: [
                          _buildSubItem(
                            label: 'Empleados',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const EmpleadosPendientesDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Funciones',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const FuncionesDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Insumos',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const InsumosDeskScreen(),
                              );
                            },
                          ),
                        ],
                      ),
                      _buildExpandableItem(
                        icon: Icons.bar_chart,
                        title: 'Reportes',
                        menuKey: 'reportes',
                        subItems: [
                          _buildSubItem(
                            label: 'Ventas',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const ReporteVentasDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Inventario',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const ReporteInventarioDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Transporte',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const ReporteTransporteDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Auditoría',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const AuditoriaDeskScreen(),
                              );
                            },
                          ),
                        ],
                      ),
                      _buildExpandableItem(
                        icon: Icons.contacts,
                        title: 'Directorio',
                        menuKey: 'directorio',
                        subItems: [
                          _buildSubItem(
                            label: 'Proformas',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const OpcionesProformasDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Clientes',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const ClientesDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Proveedores',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const ProveedoresDeskScreen(),
                              );
                            },
                          ),
                        ],
                      ),
                      _buildExpandableItem(
                        icon: Icons.settings,
                        title: 'Ajustes',
                        menuKey: 'ajustes',
                        subItems: [
                          _buildSubItem(
                            label: 'Editar Perfil',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const EditarPerfilDeskScreen(),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Enviar Feedback',
                            onTap: () {
                              _navegarConFade(
                                context,
                                const FeedbackDeskScreen(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // BOTÓN DE CERRAR SESIÓN
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENIDO PRINCIPAL
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMainItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildExpandableItem({
    required IconData icon,
    required String title,
    required String menuKey,
    required List<Widget> subItems,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Icon(
        _expandedMenu == menuKey ? Icons.expand_less : Icons.expand_more,
        color: Colors.white,
      ),
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      initiallyExpanded: _expandedMenu == menuKey,
      onExpansionChanged: (_) => _toggleMenu(menuKey),
      children: subItems,
    );
  }

  Widget _buildSubItem({required String label, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72),
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: onTap,
    );
  }
}
