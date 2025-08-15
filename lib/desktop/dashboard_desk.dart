import 'package:basefundi/desktop/dash_bajostock_desk.dart';
import 'package:basefundi/desktop/fundicion/tareas_cumplir_desk.dart';
import 'package:basefundi/desktop/personal/funciones/tareas_realizar_desk.dart';
import 'package:basefundi/desktop/personal/insumos/insumos_desk.dart';
import 'package:basefundi/modulos/ajustes_desk.dart';
import 'package:basefundi/modulos/directorio_desk.dart';
import 'package:basefundi/modulos/fundicion.dart';
import 'package:basefundi/modulos/inventario_desk.dart';
import 'package:basefundi/modulos/personal_desk.dart';
import 'package:basefundi/modulos/reportes_desk.dart';
import 'package:basefundi/modulos/ventas_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

class DashboardDeskScreen extends StatefulWidget {
  const DashboardDeskScreen({super.key});

  @override
  State<DashboardDeskScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardDeskScreen>
    with WidgetsBindingObserver {
  String nombreUsuario = '';
  String rolUsuario = 'Empleado';
  String sedeUsuario = '';

  int ventasRealizadas = 0;
  int productosVendidos = 0;
  double ingresosDia = 0.0;
  int productosBajoStock = 0;

  bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarNombreYRolUsuario();
    _cargarResumenHoy();
  }

  Future<void> _cargarNombreYRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nombreUsuario = data['nombre'] ?? 'Usuario';
        rolUsuario = data['rol'] ?? 'Empleado';
        sedeUsuario =
            (data['sede'] ?? '').toString().trim().isEmpty
                ? 'Sin sede'
                : data['sede'];
      });
    }
  }

  Future<void> _cargarResumenHoy() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final ventasQuery =
        await FirebaseFirestore.instance
            .collection('ventas')
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

    int totalVentas = ventasQuery.docs.length;
    int totalProductos = 0;
    double totalIngresos = 0.0;

    for (var doc in ventasQuery.docs) {
      final data = doc.data();
      totalIngresos += (data['total'] ?? 0.0).toDouble();
      final productos = data['productos'] as List<dynamic>? ?? [];
      for (var producto in productos) {
        totalProductos += (producto['cantidad'] ?? 0) as int;
      }
    }

    final inventarioSnapshot =
        await FirebaseFirestore.instance
            .collection('inventarios')
            .orderBy('fecha_actualizacion', descending: true)
            .get();

    final ventasSnapshot =
        await FirebaseFirestore.instance.collection('ventas').get();
    final Map<String, int> ventasPorReferencia = {};
    for (var venta in ventasSnapshot.docs) {
      final productos = List<Map<String, dynamic>>.from(venta['productos']);
      for (var producto in productos) {
        final referencia = producto['referencia']?.toString() ?? '';
        final cantidad = (producto['cantidad'] ?? 0) as num;
        ventasPorReferencia[referencia] =
            (ventasPorReferencia[referencia] ?? 0) + cantidad.toInt();
      }
    }

    final Map<String, int> stockFinal = {};
    for (var doc in inventarioSnapshot.docs) {
      final data = doc.data();
      final referencia = (data['referencia'] ?? '').toString();
      final cantidad = (data['cantidad'] ?? 0) as int;
      final tipo = (data['tipo'] ?? 'entrada').toString();
      final ajuste = tipo == 'salida' ? -cantidad : cantidad;
      stockFinal[referencia] = (stockFinal[referencia] ?? 0) + ajuste;
    }

    ventasPorReferencia.forEach((referencia, cantidadVendida) {
      if (stockFinal.containsKey(referencia)) {
        stockFinal[referencia] = stockFinal[referencia]! - cantidadVendida;
      }
    });

    int bajoStock = stockFinal.values.where((cantidad) => cantidad < 5).length;

    setState(() {
      ventasRealizadas = totalVentas;
      productosVendidos = totalProductos;
      ingresosDia = totalIngresos;
      productosBajoStock = bajoStock;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 22),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola $nombreUsuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sede $sedeUsuario',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ CONTENIDO PRINCIPAL CON FONDO BLANCO EXPLÍCITO
          Expanded(
            child: Container(
              color: Colors.white, // 🎯 FONDO BLANCO EXPLÍCITO
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildResumenHoy(),
                          const SizedBox(height: 20),
                          _buildGridFunctions(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenHoy() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4682B4), Color(0xFF5a8cc7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Hoy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildResumenItem(
                  value: ventasRealizadas.toString(),
                  label: 'Ventas Realizadas',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildResumenItem(
                  value: productosVendidos.toString(),
                  label: 'Productos Vendidos',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildResumenItem(
                  value: '\$${ingresosDia.toStringAsFixed(0)}',
                  label: 'Ingresos del Día',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildResumenItemClickeable(
                  value: productosBajoStock.toString(),
                  label: 'Productos Bajo Stock',
                  onTap: () {
                    navegarConFade(context, const BajoStockDeskScreen());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResumenItemClickeable({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildResumenItem(value: value, label: label),
    );
  }

  Widget _buildGridFunctions() {
    int crossAxisCount = isDesktop ? 5 : 3;

    List<Widget> botones = [];

    switch (rolUsuario) {
      case 'Administrador General':
        botones = [
          _gridButton(
            Icons.attach_money,
            'Ventas',
            () => navegarConFade(context, const VentasDeskScreen()),
          ),
          _gridButton(
            Icons.inventory_2,
            'Inventario',
            () => navegarConFade(context, const InventarioDeskScreen()),
          ),
          _gridButton(
            Icons.people,
            'Personal',
            () => navegarConFade(context, const PersonalDeskScreen()),
          ),
          _gridButton(
            Icons.calculate,
            'Directorio',
            () => navegarConFade(context, const DirectorioDeskScreen()),
          ),
          _gridButton(
            Icons.local_fire_department,
            'Fundición',
            () => navegarConFade(context, const FundicionDeskScreen()),
          ),
          _gridButton(
            Icons.bar_chart,
            'Reportes',
            () => navegarConFade(context, const ReportesDeskScreen()),
          ),

          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Gerente Sede':
        botones = [
          _gridButton(
            Icons.attach_money,
            'Ventas',
            () => navegarConFade(context, const VentasDeskScreen()),
          ),
          _gridButton(
            Icons.inventory_2,
            'Inventario',
            () => navegarConFade(context, const InventarioDeskScreen()),
          ),
          _gridButton(
            Icons.bar_chart,
            'Reportes',
            () => navegarConFade(context, const ReportesDeskScreen()),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Supervisor Fundición':
        botones = [
          _gridButton(
            Icons.local_fire_department,
            'Fundición',
            () => navegarConFade(context, const FundicionDeskScreen()),
          ),
          _gridButton(
            Icons.bar_chart,
            'Insumos',
            () => navegarConFade(context, const InsumosDeskScreen()),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Operador Fundición':
        botones = [
          _gridButton(
            Icons.task_alt,
            'Tareas',
            () => navegarConFade(
              context,
              const OperadorTareasScreen(operadorId: '', operadorNombre: ''),
            ),
          ),
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
        break;

      case 'Supervisor Mecanizado':
        botones = [
          _gridButton(
            Icons.inventory_2,
            'Inventario',
            () => navegarConFade(context, const InventarioDeskScreen()),
          ),
          _gridButton(
            Icons.task_alt,
            'Tareas',
            () => navegarConFade(context, const TareasPendientesDeskScreen()),
          ),
          _gridButton(
            Icons.bar_chart,
            'Reportes',
            () => navegarConFade(context, const ReportesDeskScreen()),
          ),
        ];
        break;

      case 'Operador Mecanizado':
        botones = [
          _gridButton(
            Icons.task_alt,
            'Tareas',
            () => navegarConFade(context, const TareasPendientesDeskScreen()),
          ),
        ];
        break;

      default:
        botones = [
          _gridButton(
            Icons.settings,
            'Ajustes',
            () => navegarConFade(context, const SettingsDeskScreen()),
          ),
        ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        children: botones,
      ),
    );
  }

  Widget _gridButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF4682B4), size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
