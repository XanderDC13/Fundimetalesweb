import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReporteInventarioScreen extends StatefulWidget {
  const ReporteInventarioScreen({super.key});

  @override
  _ReporteInventarioScreenState createState() =>
      _ReporteInventarioScreenState();
}

class _ReporteInventarioScreenState extends State<ReporteInventarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroNombre = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildListaEntradas(String coleccion) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(coleccion)
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final entradas =
            docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .where(
                  (e) => (e['nombre'] ?? '').toString().toLowerCase().contains(
                    _filtroNombre.toLowerCase(),
                  ),
                )
                .toList();

        if (entradas.isEmpty) {
          return const Center(child: Text('No hay entradas registradas.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: entradas.length,
          itemBuilder: (context, index) {
            final entrada = entradas[index];
            final fecha =
                entrada['fecha'] != null
                    ? (entrada['fecha'] as Timestamp).toDate()
                    : null;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entrada['codigo'] ?? '-'} - ${entrada['nombre'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cantidad: +${entrada['cantidad'] ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4682B4),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fecha: ${fecha != null ? fecha.toLocal().toString().split(' ')[0] : '-'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (entrada['hora'] != null)
                      Text(
                        'Hora: ${entrada['hora']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar con diseño original (sin usar AppBar widget para personalizar)
            Container(
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
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: const Text(
                'Reporte de Inventario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filtroNombre = value;
                  });
                },
              ),
            ),

            // Pestañas debajo de la barra de búsqueda
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF4682B4),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF4682B4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF4682B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Fundición'),
                    Tab(text: 'Pintura'),
                    Tab(text: 'General'),
                  ],
                ),
              ),
            ),

            // Contenido pestañas
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListaEntradas('inventario_fundicion'),
                  _buildListaEntradas('inventario_pintura'),
                  _buildListaEntradas('historial_inventario_general'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
