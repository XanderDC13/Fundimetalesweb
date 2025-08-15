import 'package:basefundi/desktop/ajustes/editperfil_desk.dart';
import 'package:basefundi/desktop/ajustes/feedback_desk.dart';
import 'package:basefundi/desktop/dashboard_desk.dart';
import 'package:basefundi/desktop/directorio/clientes_desk.dart';
import 'package:basefundi/desktop/directorio/pedidos_desk.dart';
import 'package:basefundi/desktop/directorio/proformas_desk.dart';
import 'package:basefundi/desktop/directorio/proveedores_desk.dart';
import 'package:basefundi/desktop/fundicion/tareas_cumplir_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_fundicion_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_general_desk.dart';
import 'package:basefundi/desktop/inventario/inventario_procesos_desk.dart';
import 'package:basefundi/desktop/inventario/productos_desk.dart';
import 'package:basefundi/desktop/inventario/transporte_desk.dart';
import 'package:basefundi/desktop/personal/empleados/empleados_registro_desk.dart';
import 'package:basefundi/desktop/personal/funciones/tareas_empleados_desk.dart';
import 'package:basefundi/desktop/personal/funciones/tareas_realizar_desk.dart';
import 'package:basefundi/desktop/personal/insumos/insumos_desk.dart';
import 'package:basefundi/desktop/reportes/auditoria_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_compras_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_inv_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_transporte_desk.dart';
import 'package:basefundi/desktop/reportes/reporte_ventas_desk.dart';
import 'package:basefundi/desktop/ventas/modificar_ventas_desk.dart';
import 'package:basefundi/desktop/ventas/realizar_venta_desk.dart';
import 'package:basefundi/desktop/ventas/ventas_totales_desk.dart';
import 'package:basefundi/modulos/ajustes_desk.dart';
import 'package:basefundi/modulos/fundicion.dart';
import 'package:basefundi/modulos/inventario_desk.dart';
import 'package:basefundi/modulos/reportes_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class MainDeskLayout extends StatefulWidget {
  final Widget child;

  const MainDeskLayout({super.key, required this.child});

  @override
  State<MainDeskLayout> createState() => _MainDeskLayoutState();
}

class _MainDeskLayoutState extends State<MainDeskLayout> {
  String? _expandedMenu;
  String rolUsuario = 'Empleado'; // Rol por defecto

  @override
  void initState() {
    super.initState();
    _cargarRolUsuario();
  }

  Future<void> _cargarRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          rolUsuario = data['rol'] ?? 'Empleado';
        });
      }
    } catch (e) {
      print('Error al cargar rol del usuario: $e');
    }
  }

  void _toggleMenu(String menu) {
    setState(() {
      if (_expandedMenu == menu) {
        _expandedMenu = null;
      } else {
        _expandedMenu = menu;
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    context.go('/login');
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

                Expanded(child: ListView(children: _buildMenuItems())),

                // BOTÓN DE CERRAR SESIÓN
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed:
                        () => _logout(context), // ahora sí es un VoidCallback
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

  List<Widget> _buildMenuItems() {
  List<Widget> menuItems = [
    _buildMainItem(
      icon: Icons.home,
      title: 'Inicio',
      onTap: () {
        navegarConFade(context, const DashboardDeskScreen());
      },
    ),
  ];

  switch (rolUsuario) {
    case 'Administrador General':
      menuItems.addAll([
        _buildExpandableItem(
          icon: Icons.shopping_cart,
          title: 'Ventas',
          menuKey: 'ventas',
          subItems: [
            _buildSubItem(
              label: 'Ventas Totales',
              onTap: () => navegarConFade(context, const VentasTotalesDeskScreen()),
            ),
            _buildSubItem(
              label: 'Modificar Ventas',
              onTap: () => navegarConFade(context, const ModificarVentaDeskScreen()),
            ),
            _buildSubItem(
              label: 'Realizar Venta',
              onTap: () => navegarConFade(context, const VentasDetalleDeskScreen()),
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
              onTap: () => navegarConFade(context, const TotalInvDeskScreen()),
            ),
            _buildSubItem(
              label: 'General',
              onTap: () => navegarConFade(context, const InventarioGeneralDeskScreen()),
            ),
            _buildSubItem(
              label: 'Fundición',
              onTap: () => navegarConFade(context, const InventarioFundicionDeskScreen()),
            ),
            _buildSubItem(
              label: 'Pintura',
              onTap: () => navegarConFade(context, const InventarioProcesoDeskScreen()),
            ),
            _buildSubItem(
              label: 'Transporte',
              onTap: () => navegarConFade(context, const TransporteDeskScreen()),
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
              onTap: () => navegarConFade(context, const EmpleadosPendientesDeskScreen()),
            ),
            _buildSubItem(
              label: 'Funciones',
              onTap: () => navegarConFade(context, const FuncionesDeskScreen()),
            ),
            _buildSubItem(
              label: 'Insumos',
              onTap: () => navegarConFade(context, const InsumosDeskScreen()),
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
              onTap: () => navegarConFade(context, const ReporteVentasDeskScreen()),
            ),
            _buildSubItem(
              label: 'Inventario',
              onTap: () => navegarConFade(context, const ReporteInventarioDeskScreen()),
            ),
            _buildSubItem(
              label: 'Compras',
              onTap: () => navegarConFade(context, const ReporteComprasDeskScreen()),
            ),
            _buildSubItem(
              label: 'Transporte',
              onTap: () => navegarConFade(context, const ReporteTransporteDeskScreen()),
            ),
            _buildSubItem(
              label: 'Auditoría',
              onTap: () => navegarConFade(context, const AuditoriaDeskScreen()),
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
              onTap: () => navegarConFade(context, const OpcionesProformasDeskScreen()),
            ),
            _buildSubItem(
              label: 'Pedidos',
              onTap: () => navegarConFade(context, const PedidosDeskScreen()),
            ),
            _buildSubItem(
              label: 'Clientes',
              onTap: () => navegarConFade(context, const ClientesDeskScreen()),
            ),
            _buildSubItem(
              label: 'Proveedores',
              onTap: () => navegarConFade(context, const ProveedoresDeskScreen()),
            ),
          ],
        ),
      ]);
      break;

    case 'Gerente Sede':
      menuItems.addAll([
        _buildExpandableItem(
          icon: Icons.shopping_cart,
          title: 'Ventas',
          menuKey: 'ventas',
          subItems: [
            _buildSubItem(
              label: 'Realizar Venta',
              onTap: () => navegarConFade(context, const VentasDetalleDeskScreen()),
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
              onTap: () => navegarConFade(context, const InventarioGeneralDeskScreen()),
            ),
          ],
        ),
        _buildMainItem(
          icon: Icons.bar_chart,
          title: 'Reportes',
          onTap: () => navegarConFade(context, const ReportesDeskScreen()),
        ),
      ]);
      break;

    case 'Supervisor Fundición':
      menuItems.addAll([
        _buildMainItem(
          icon: Icons.local_fire_department,
          title: 'Fundición',
          onTap: () => navegarConFade(context, const FundicionDeskScreen()),
        ),
        _buildMainItem(
          icon: Icons.bar_chart,
          title: 'Insumos',
          onTap: () => navegarConFade(context, const InsumosDeskScreen()),
        ),
      ]);
      break;

    case 'Operador Fundición':
      menuItems.addAll([
        _buildMainItem(
          icon: Icons.task_alt,
          title: 'Tareas',
          onTap: () => navegarConFade(
            context,
            OperadorTareasScreen(
              operadorId: '',
              operadorNombre: '',
            ),
          ),
        ),
      ]);
      break;

    case 'Supervisor Mecanizado':
      menuItems.addAll([
        _buildMainItem(
          icon: Icons.inventory,
          title: 'Inventario',
          onTap: () => navegarConFade(context, const InventarioDeskScreen()),
        ),
        _buildMainItem(
          icon: Icons.task_alt,
          title: 'Tareas',
          onTap: () => navegarConFade(context, const TareasPendientesDeskScreen()),
        ),
        _buildMainItem(
          icon: Icons.bar_chart,
          title: 'Reportes',
          onTap: () => navegarConFade(context, const ReportesDeskScreen()),
        ),
      ]);
      break;

    case 'Operador Mecanizado':
      menuItems.add(
        _buildMainItem(
          icon: Icons.task_alt,
          title: 'Tareas',
          onTap: () => navegarConFade(context, const TareasPendientesDeskScreen()),
        ),
      );
      break;

    default:
      menuItems.add(
        _buildMainItem(
          icon: Icons.settings,
          title: 'Ajustes',
          onTap: () => navegarConFade(context, const SettingsDeskScreen()),
        ),
      );
  }

  // Ajustes siempre al final
  menuItems.add(
    _buildExpandableItem(
      icon: Icons.settings,
      title: 'Ajustes',
      menuKey: 'ajustes',
      subItems: [
        _buildSubItem(
          label: 'Editar Perfil',
          onTap: () => navegarConFade(context, const EditarPerfilDeskScreen()),
        ),
        _buildSubItem(
          label: 'Enviar Feedback',
          onTap: () => navegarConFade(context, const FeedbackDeskScreen()),
        ),
      ],
    ),
  );

  return menuItems;
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
