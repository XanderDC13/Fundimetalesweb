import 'package:basefundi/modulos/directorio_movil.dart';
import 'package:basefundi/modulos/inventario_movil.dart';
import 'package:basefundi/modulos/personal_movil.dart';
import 'package:basefundi/movil/personal/funciones/tareas_realizar_movil.dart';
import 'package:basefundi/modulos/reportes_movil.dart';
import 'package:basefundi/movil/dash_bajostock_movil.dart';
import 'package:basefundi/modulos/ventas_movil.dart';
import 'package:basefundi/modulos/ajustes_movil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// imports mantenidos

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  String nombreUsuario = '';
  String rolUsuario = 'Empleado';
  String sedeUsuario = '';

  // Variables para el resumen de hoy
  int ventasRealizadas = 0;
  int productosVendidos = 0;
  double ingresosDia = 0.0;
  int productosBajoStock = 0;

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
        rolUsuario = data['rol'] ?? 'empleado';
        sedeUsuario =
            (data['sede'] ?? '').toString().trim().isEmpty
                ? 'Sin sede'
                : data['sede'];
      });
    }
  }

  Future<void> _cargarResumenHoy() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Cargar ventas del día
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

      // Traer historial de inventario
      final inventarioSnapshot =
          await FirebaseFirestore.instance
              .collection('historial_inventario_general')
              .orderBy('fecha_actualizacion', descending: true)
              .get();

      // Traer ventas totales para restar
      final ventasSnapshot =
          await FirebaseFirestore.instance.collection('ventas').get();
      final ventasDocs = ventasSnapshot.docs;

      // Agrupar ventas por REFERENCIA
      final Map<String, int> ventasPorReferencia = {};
      for (var venta in ventasDocs) {
        final productos = List<Map<String, dynamic>>.from(venta['productos']);
        for (var producto in productos) {
          final referencia = producto['referencia']?.toString() ?? '';
          final cantidad = (producto['cantidad'] ?? 0) as num;
          ventasPorReferencia[referencia] =
              (ventasPorReferencia[referencia] ?? 0) + cantidad.toInt();
        }
      }

      // Procesar inventario agrupado POR REFERENCIA
      final Map<String, int> stockFinal = {};
      for (var doc in inventarioSnapshot.docs) {
        final data = doc.data();
        final referencia =
            (data['referencia'] ?? '').toString(); // ✅ usar referencia
        final cantidad = (data['cantidad'] ?? 0) as int;
        final tipo = (data['tipo'] ?? 'entrada').toString();

        final ajuste = tipo == 'salida' ? -cantidad : cantidad;
        stockFinal[referencia] = (stockFinal[referencia] ?? 0) + ajuste;
      }

      // Restar ventas al inventario
      ventasPorReferencia.forEach((referencia, cantidadVendida) {
        if (stockFinal.containsKey(referencia)) {
          stockFinal[referencia] = stockFinal[referencia]! - cantidadVendida;
        }
      });

      // Contar referencias con stock bajo (< 10)
      int bajoStock =
          stockFinal.values.where((cantidad) => cantidad < 5).length;

      setState(() {
        ventasRealizadas = totalVentas;
        productosVendidos = totalProductos;
        ingresosDia = totalIngresos;
        productosBajoStock = bajoStock;
      });
    } catch (e) {
      print('Error al cargar resumen del día: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFD6EAF8),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildResumenHoy(),
                      const SizedBox(height: 20),
                      _buildGridFunctions(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola $nombreUsuario',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sede $sedeUsuario',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenHoy() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4682B4), Color(0xFF5a8cc7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              fontSize: 20,
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
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildResumenItem(
                  value: '\$${ingresosDia.toStringAsFixed(0)}',
                  label: 'Ingresos del Día',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildResumenItemClickable(
                  value: productosBajoStock.toString(),
                  label: 'Productos Bajo Stock',
                  onTap: () {
                    _navegarConFade(context, const BajoStockScreen());
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResumenItemClickable({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navegarConFade(BuildContext context, Widget pantalla) {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => pantalla,
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 150),
          ),
        )
        .then((_) {
          // Recargar datos cuando se regrese al dashboard
          _cargarResumenHoy();
        });
  }

  Widget _buildGridFunctions() {
    if (rolUsuario == 'Administrador') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _gridButton(Icons.attach_money, 'Ventas', () {
              _navegarConFade(context, const VentasScreen());
            }),
            _gridButton(Icons.inventory_2, 'Inventario', () {
              _navegarConFade(context, const InventarioScreen());
            }),
            _gridButton(Icons.people, 'Personal', () {
              _navegarConFade(context, const PersonalScreen());
            }),
            _gridButton(Icons.bar_chart, 'Reportes', () {
              _navegarConFade(context, const ReportesScreen());
            }),
            _gridButton(Icons.calculate, 'Directorio', () {
              _navegarConFade(context, const DirectorioScreen());
            }),
            _gridButton(Icons.settings, 'Ajustes', () {
              _navegarConFade(context, const SettingsScreen());
            }),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _gridButton(Icons.attach_money, 'Ventas', () {
              _navegarConFade(context, const VentasScreen());
            }),
            _gridButton(Icons.inventory_2, 'Inventario', () {
              _navegarConFade(context, const InventarioScreen());
            }),
            _gridButton(Icons.task_alt, 'Tareas', () {
              _navegarConFade(context, const TareasPendientesScreen());
            }),
            _gridButton(Icons.settings, 'Ajustes', () {
              _navegarConFade(context, const SettingsScreen());
            }),
          ],
        ),
      );
    }
  }

  Widget _gridButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF4682B4), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
