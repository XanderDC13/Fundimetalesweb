import 'package:basefundi/screens/inventario.dart';
import 'package:basefundi/screens/personal.dart';
import 'package:basefundi/screens/reportes.dart';
import 'package:basefundi/screens/ventas.dart';
import 'package:basefundi/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String productosFiltro = 'Diario';
  String inventarioFiltro = 'Diario';
  List<List<String>> productosMasVendidos = [];
  List<List<String>> inventarioBajo = [];
  String nombreUsuario = '';

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
    _cargarInventarioBajo();
  }

  Future<void> _cargarNombreUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No hay usuario autenticado');
      return;
    }

    print('UID actual: ${user.uid}');

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        print("Documento encontrado: ${doc.data()}");
        setState(() {
          nombreUsuario = doc.data()?['nombre'] ?? 'Usuario';
        });
      } else {
        print("Documento no encontrado para UID: ${user.uid}");
      }
    } catch (e) {
      print('Error cargando nombre de usuario: $e');
    }
  }

  Future<void> _cargarInventarioBajo() async {
    final inventarioSnapshot =
        await FirebaseFirestore.instance.collection('inventario_general').get();

    final ventasSnapshot =
        await FirebaseFirestore.instance.collection('ventas').get();

    final Map<String, int> productosVendidos = {};

    for (var venta in ventasSnapshot.docs) {
      final productos = List<Map<String, dynamic>>.from(venta['productos']);
      for (var producto in productos) {
        final codigo = producto['codigo'];
        final cantidad = producto['cantidad'];
        if (codigo != null && cantidad != null) {
          productosVendidos[codigo] =
              (productosVendidos[codigo] ?? 0) + (cantidad as int);
        }
      }
    }

    final List<List<String>> inventario = [
      ['Producto', 'Cantidad Disponible'],
    ];

    for (var doc in inventarioSnapshot.docs) {
      final data = doc.data();
      final nombre = data['nombre'] ?? 'Sin nombre';
      final codigo = data['codigo'] ?? '';
      final cantidad = data['cantidad'] ?? 0;

      final cantidadVendida = productosVendidos[codigo] ?? 0;
      final cantidadDisponible = cantidad - cantidadVendida;

      if (cantidadDisponible < 10) {
        inventario.add([nombre.toString(), cantidadDisponible.toString()]);
      }
    }

    setState(() {
      inventarioBajo = inventario;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'PRODUCTOS MÁS VENDIDOS',
                filterValue: productosFiltro,
                onFilterChanged:
                    (value) => setState(() => productosFiltro = value),
                child:
                    productosMasVendidos.isEmpty
                        ? const Text('Sin datos')
                        : _buildStyledTable(productosMasVendidos),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'INVENTARIO BAJO',
                filterValue: inventarioFiltro,
                onFilterChanged:
                    (value) => setState(() => inventarioFiltro = value),
                child:
                    inventarioBajo.isEmpty
                        ? const Text('Sin datos')
                        : _buildStyledTable(inventarioBajo),
              ),
              const SizedBox(height: 20),
              _buildGridFunctions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                nombreUsuario.isEmpty ? '' : nombreUsuario,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Image.asset(
            'lib/assets/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String filterValue,
    required void Function(String) onFilterChanged,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: filterValue,
                  items:
                      ['Diario', 'Mensual', 'Anual']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) => onFilterChanged(value ?? ''),
                  underline: Container(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(color: Color(0xFF1E40AF)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTable(List<List<String>> rows) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children: List.generate(rows.length, (index) {
        final isHeader = index == 0;
        final style = TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          color: isHeader ? Colors.black87 : Colors.black54,
        );
        return TableRow(
          children:
              rows[index]
                  .map(
                    (cell) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(cell, style: style),
                    ),
                  )
                  .toList(),
        );
      }),
    );
  }

  Widget _buildGridFunctions() {
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
          _gridButton(Icons.settings, 'Ajustes', () {
            _navegarConFade(context, const SettingsScreen());
          }),
        ],
      ),
    );
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
            child: Icon(icon, color: Color(0xFF1E3A8A), size: 30),
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
