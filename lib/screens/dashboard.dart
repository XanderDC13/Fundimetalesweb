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
  List<List<String>> productosMasVendidos = [];
  List<List<String>> inventarioBajo = [];
  String nombreUsuario = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
    _cargarInventarioBajo();
    _cargarProductosMasVendidos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarNombreUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user.uid)
            .get();

    if (doc.exists) {
      setState(() {
        nombreUsuario = doc.data()?['nombre'] ?? 'Usuario';
      });
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
      ['Producto', 'Cant Disponible'],
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

    inventario.sort((a, b) {
      if (a == inventario[0]) return -1;
      if (b == inventario[0]) return 1;
      return int.parse(a[1]).compareTo(int.parse(b[1]));
    });

    setState(() {
      inventarioBajo = inventario;
    });
  }

  Future<void> _cargarProductosMasVendidos() async {
    final now = DateTime.now();
    late DateTime startDate;

    if (productosFiltro == 'Diario') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (productosFiltro == 'Mensual') {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }

    final ventasSnapshot =
        await FirebaseFirestore.instance
            .collection('ventas')
            .where('fecha', isGreaterThanOrEqualTo: startDate)
            .get();

    final Map<String, int> productosVendidos = {};
    final Map<String, String> nombresProductos = {};

    for (var venta in ventasSnapshot.docs) {
      final productos = List<Map<String, dynamic>>.from(venta['productos']);
      for (var producto in productos) {
        final codigo = producto['codigo'];
        final cantidad = producto['cantidad'];
        final nombre = producto['nombre'];

        if (codigo != null && cantidad != null) {
          productosVendidos[codigo] =
              (productosVendidos[codigo] ?? 0) + (cantidad as int);
          nombresProductos[codigo] = nombre ?? 'Sin nombre';
        }
      }
    }

    final topProductos =
        productosVendidos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final List<List<String>> top3 = [
      ['Producto', 'Cant Vendida'],
    ];

    for (var i = 0; i < topProductos.length && i < 3; i++) {
      final codigo = topProductos[i].key;
      final cantidad = topProductos[i].value;
      final nombre = nombresProductos[codigo] ?? 'Sin nombre';

      top3.add([nombre, cantidad.toString()]);
    }

    setState(() {
      productosMasVendidos = top3;
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
                onFilterChanged: (value) {
                  setState(() => productosFiltro = value);
                  _cargarProductosMasVendidos();
                },
                child:
                    productosMasVendidos.isEmpty
                        ? const Text('Sin datos')
                        : _buildStyledTable(
                          productosMasVendidos,
                          scrollable: false,
                        ),
              ),
              const SizedBox(height: 16),
              _buildSimpleSectionCard(
                title: 'INVENTARIO BAJO',
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

  Widget _buildSimpleSectionCard({
    required String title,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTable(List<List<String>> rows, {bool scrollable = true}) {
    final header = rows[0];
    final dataRows = rows.length > 1 ? rows.sublist(1) : [];

    return Column(
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
          border: TableBorder(
            bottom: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          children: [
            TableRow(
              children:
                  header
                      .map(
                        (cell) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            cell,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (scrollable)
          SizedBox(
            height: 100,
            child: Scrollbar(
              thumbVisibility: true,
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildTableBody(dataRows.cast<List<String>>()),
              ),
            ),
          )
        else
          _buildTableBody(dataRows.cast<List<String>>()),
      ],
    );
  }

  Widget _buildTableBody(List<List<String>> dataRows) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children:
          dataRows
              .map(
                (row) => TableRow(
                  children:
                      row
                          .map(
                            (cell) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                cell,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              )
              .toList(),
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
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 30),
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
