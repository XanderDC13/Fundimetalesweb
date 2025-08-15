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
import 'dart:async';

class MenuStateManager {
  static final MenuStateManager _instance = MenuStateManager._internal();
  factory MenuStateManager() => _instance;
  MenuStateManager._internal();

  String? _expandedMenu;
  String _rolUsuario = 'Empleado';
  bool _isInitialized = false;

  String? get expandedMenu => _expandedMenu;
  String get rolUsuario => _rolUsuario;
  bool get isInitialized => _isInitialized;

  void setExpandedMenu(String? menu) {
    _expandedMenu = menu;
  }

  void setRolUsuario(String rol) {
    _rolUsuario = rol;
    _isInitialized = true;
  }

  void toggleMenu(String menu) {
    if (_expandedMenu == menu) {
      _expandedMenu = null;
    } else {
      _expandedMenu = menu;
    }
  }
}

class MainDeskLayout extends StatefulWidget {
  final Widget child;

  const MainDeskLayout({super.key, required this.child});

  @override
  State<MainDeskLayout> createState() => _MainDeskLayoutState();
}

class _MainDeskLayoutState extends State<MainDeskLayout> with AutomaticKeepAliveClientMixin {
  final MenuStateManager _menuStateManager = MenuStateManager();
  late StreamSubscription<User?> _authSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMenuState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && !_menuStateManager.isInitialized) {
        _cargarRolUsuario();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _initializeMenuState() {
    if (!_menuStateManager.isInitialized) {
      _cargarRolUsuario();
    }
  }

  Future<void> _cargarRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios_activos')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final rol = data['rol'] ?? 'Empleado';
        _menuStateManager.setRolUsuario(rol);
        setState(() {});
      }
    } catch (e) {
      print('Error al cargar rol del usuario: $e');
    }
  }

  void _toggleMenu(String menu) {
    setState(() {
      _menuStateManager.toggleMenu(menu);
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFF2C3E50),
            child: Column(
              children: [
                _buildMenuHeader(),
                Expanded(
                  child: ListView(
                    key: const ValueKey('menu_list'), 
                    children: _buildMenuItems(),
                  ),
                ),
                _buildLogoutButton(context),
              ],
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text(
            'Fundimetales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _menuStateManager.rolUsuario,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: TextButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Colors.white),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    List<Widget> menuItems = [
      _buildMainItem(
        icon: Icons.home,
        title: 'Inicio',
        onTap: () => _navigateToScreen(const DashboardDeskScreen()),
      ),
    ];

    switch (_menuStateManager.rolUsuario) {
      case 'Administrador General':
        menuItems.addAll(_buildAdminMenuItems());
        break;
      case 'Gerente Sede':
        menuItems.addAll(_buildGerenteMenuItems());
        break;
      case 'Supervisor Fundición':
        menuItems.addAll(_buildSupervisorFundicionMenuItems());
        break;
      case 'Operador Fundición':
        menuItems.addAll(_buildOperadorFundicionMenuItems());
        break;
      case 'Supervisor Mecanizado':
        menuItems.addAll(_buildSupervisorMecanizadoMenuItems());
        break;
      case 'Operador Mecanizado':
        menuItems.addAll(_buildOperadorMecanizadoMenuItems());
        break;
      default:
        menuItems.add(_buildDefaultMenuItem());
    }

    menuItems.add(_buildAjustesMenuItem());

    return menuItems;
  }

  void _navigateToScreen(Widget screen) {
    if (mounted) {
      navegarConFade(context, screen);
    }
  }

  List<Widget> _buildAdminMenuItems() {
    return [
      _buildExpandableItem(
        icon: Icons.shopping_cart,
        title: 'Ventas',
        menuKey: 'ventas',
        subItems: [
          _buildSubItem(
            label: 'Ventas Totales',
            onTap: () => _navigateToScreen(const VentasTotalesDeskScreen()),
          ),
          _buildSubItem(
            label: 'Modificar Ventas',
            onTap: () => _navigateToScreen(const ModificarVentaDeskScreen()),
          ),
          _buildSubItem(
            label: 'Realizar Venta',
            onTap: () => _navigateToScreen(const VentasDetalleDeskScreen()),
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
            onTap: () => _navigateToScreen(const TotalInvDeskScreen()),
          ),
          _buildSubItem(
            label: 'General',
            onTap: () => _navigateToScreen(const InventarioGeneralDeskScreen()),
          ),
          _buildSubItem(
            label: 'Fundición',
            onTap: () => _navigateToScreen(const InventarioFundicionDeskScreen()),
          ),
          _buildSubItem(
            label: 'Pintura',
            onTap: () => _navigateToScreen(const InventarioProcesoDeskScreen()),
          ),
          _buildSubItem(
            label: 'Transporte',
            onTap: () => _navigateToScreen(const TransporteDeskScreen()),
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
            onTap: () => _navigateToScreen(const EmpleadosPendientesDeskScreen()),
          ),
          _buildSubItem(
            label: 'Funciones',
            onTap: () => _navigateToScreen(const FuncionesDeskScreen()),
          ),
          _buildSubItem(
            label: 'Insumos',
            onTap: () => _navigateToScreen(const InsumosDeskScreen()),
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
            onTap: () => _navigateToScreen(const ReporteVentasDeskScreen()),
          ),
          _buildSubItem(
            label: 'Inventario',
            onTap: () => _navigateToScreen(const ReporteInventarioDeskScreen()),
          ),
          _buildSubItem(
            label: 'Compras',
            onTap: () => _navigateToScreen(const ReporteComprasDeskScreen()),
          ),
          _buildSubItem(
            label: 'Transporte',
            onTap: () => _navigateToScreen(const ReporteTransporteDeskScreen()),
          ),
          _buildSubItem(
            label: 'Auditoría',
            onTap: () => _navigateToScreen(const AuditoriaDeskScreen()),
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
            onTap: () => _navigateToScreen(const OpcionesProformasDeskScreen()),
          ),
          _buildSubItem(
            label: 'Pedidos',
            onTap: () => _navigateToScreen(const PedidosDeskScreen()),
          ),
          _buildSubItem(
            label: 'Clientes',
            onTap: () => _navigateToScreen(const ClientesDeskScreen()),
          ),
          _buildSubItem(
            label: 'Proveedores',
            onTap: () => _navigateToScreen(const ProveedoresDeskScreen()),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildGerenteMenuItems() {
    return [
      _buildExpandableItem(
        icon: Icons.shopping_cart,
        title: 'Ventas',
        menuKey: 'ventas',
        subItems: [
          _buildSubItem(
            label: 'Realizar Venta',
            onTap: () => _navigateToScreen(const VentasDetalleDeskScreen()),
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
            onTap: () => _navigateToScreen(const InventarioGeneralDeskScreen()),
          ),
        ],
      ),
      _buildMainItem(
        icon: Icons.bar_chart,
        title: 'Reportes',
        onTap: () => _navigateToScreen(const ReportesDeskScreen()),
      ),
    ];
  }

  List<Widget> _buildSupervisorFundicionMenuItems() {
    return [
      _buildMainItem(
        icon: Icons.local_fire_department,
        title: 'Fundición',
        onTap: () => _navigateToScreen(const FundicionDeskScreen()),
      ),
      _buildMainItem(
        icon: Icons.bar_chart,
        title: 'Insumos',
        onTap: () => _navigateToScreen(const InsumosDeskScreen()),
      ),
    ];
  }

  List<Widget> _buildOperadorFundicionMenuItems() {
    return [
      _buildMainItem(
        icon: Icons.task_alt,
        title: 'Tareas',
        onTap: () => _navigateToScreen(
          OperadorTareasScreen(
            operadorId: '',
            operadorNombre: '',
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSupervisorMecanizadoMenuItems() {
    return [
      _buildMainItem(
        icon: Icons.inventory,
        title: 'Inventario',
        onTap: () => _navigateToScreen(const InventarioDeskScreen()),
      ),
      _buildMainItem(
        icon: Icons.task_alt,
        title: 'Tareas',
        onTap: () => _navigateToScreen(const TareasPendientesDeskScreen()),
      ),
      _buildMainItem(
        icon: Icons.bar_chart,
        title: 'Reportes',
        onTap: () => _navigateToScreen(const ReportesDeskScreen()),
      ),
    ];
  }

  List<Widget> _buildOperadorMecanizadoMenuItems() {
    return [
      _buildMainItem(
        icon: Icons.task_alt,
        title: 'Tareas',
        onTap: () => _navigateToScreen(const TareasPendientesDeskScreen()),
      ),
    ];
  }

  Widget _buildDefaultMenuItem() {
    return _buildMainItem(
      icon: Icons.settings,
      title: 'Ajustes',
      onTap: () => _navigateToScreen(const SettingsDeskScreen()),
    );
  }

  Widget _buildAjustesMenuItem() {
    return _buildExpandableItem(
      icon: Icons.settings,
      title: 'Ajustes',
      menuKey: 'ajustes',
      subItems: [
        _buildSubItem(
          label: 'Editar Perfil',
          onTap: () => _navigateToScreen(const EditarPerfilDeskScreen()),
        ),
        _buildSubItem(
          label: 'Enviar Feedback',
          onTap: () => _navigateToScreen(const FeedbackDeskScreen()),
        ),
      ],
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
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildExpandableItem({
    required IconData icon,
    required String title,
    required String menuKey,
    required List<Widget> subItems,
  }) {
    final isExpanded = _menuStateManager.expandedMenu == menuKey;
    
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey(menuKey), 
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) => _toggleMenu(menuKey),
        children: subItems,
      ),
    );
  }

  Widget _buildSubItem({
    required String label, 
    required VoidCallback onTap
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72),
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.05),
    );
  }
}