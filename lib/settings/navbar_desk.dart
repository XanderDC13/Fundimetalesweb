import 'package:basefundi/auth/login.dart';
import 'package:basefundi/desktop/dashboard_desk.dart';
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DashboardDeskScreen(),
                            ),
                          );
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const VentasTotalesDeskScreen(),
                                ),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Modificar Ventas',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const ModificarVentasDeskScreen(),
                                ),
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Realizar Venta',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const VentasDetalleDeskScreen(),
                                ),
                              );
                              ;
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
                            label: 'General',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/inventario_general_desk',
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Fundición',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/inventario_fundicion_desk',
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Pintura',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/inventario_pintura_desk',
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
                              Navigator.pushNamed(context, '/personal_desk');
                            },
                          ),
                          _buildSubItem(
                            label: 'Funciones',
                            onTap: () {
                              Navigator.pushNamed(context, '/funciones_desk');
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
                              Navigator.pushNamed(
                                context,
                                '/reporte_ventas_desk',
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Inventario',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/reporte_inventario_desk',
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Transporte',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/reporte_transporte_desk',
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
                            label: 'Clientes',
                            onTap: () {
                              Navigator.pushNamed(context, '/clientes_desk');
                            },
                          ),
                          _buildSubItem(
                            label: 'Proveedores',
                            onTap: () {
                              Navigator.pushNamed(context, '/proveedores_desk');
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
                              Navigator.pushNamed(
                                context,
                                '/editar_perfil_desk',
                              );
                            },
                          ),
                          _buildSubItem(
                            label: 'Centro de Ayuda',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/centro_ayuda_desk',
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
