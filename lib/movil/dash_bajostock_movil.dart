import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BajoStockScreen extends StatefulWidget {
  const BajoStockScreen({super.key});

  @override
  State<BajoStockScreen> createState() => _BajoStockScreenState();
}

class _BajoStockScreenState extends State<BajoStockScreen> {
  List<Map<String, dynamic>> productosBajoStock = [];
  List<Map<String, dynamic>> productosFiltrados = [];
  bool isLoading = true;
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarProductosBajoStock();
  }

  Future<void> _cargarProductosBajoStock() async {
    try {
      setState(() {
        isLoading = true;
      });

      // === TU LÓGICA ORIGINAL SIN TOCAR ===
      final inventarioSnapshot =
          await FirebaseFirestore.instance
              .collection('historial_inventario_general')
              .orderBy('fecha_actualizacion', descending: true)
              .get();

      final ventasSnapshot =
          await FirebaseFirestore.instance.collection('ventas').get();
      final ventasDocs = ventasSnapshot.docs;

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

      final Map<String, Map<String, dynamic>> stockFinal = {};
      for (var doc in inventarioSnapshot.docs) {
        final data = doc.data();
        final referencia = (data['referencia'] ?? '').toString();
        final cantidad = (data['cantidad'] ?? 0) as int;
        final tipo = (data['tipo'] ?? 'entrada').toString();
        final nombre = (data['nombre'] ?? 'Producto sin nombre').toString();
        final precio = (data['precio'] ?? 0.0).toDouble();

        final ajuste = tipo == 'salida' ? -cantidad : cantidad;

        if (stockFinal.containsKey(referencia)) {
          stockFinal[referencia]!['cantidad'] =
              (stockFinal[referencia]!['cantidad'] ?? 0) + ajuste;
        } else {
          stockFinal[referencia] = {
            'referencia': referencia,
            'nombre': nombre,
            'precio': precio,
            'cantidad': ajuste,
          };
        }
      }

      ventasPorReferencia.forEach((referencia, cantidadVendida) {
        if (stockFinal.containsKey(referencia)) {
          stockFinal[referencia]!['cantidad'] =
              (stockFinal[referencia]!['cantidad'] ?? 0) - cantidadVendida;
        }
      });

      List<Map<String, dynamic>> bajoStock = [];
      stockFinal.forEach((referencia, producto) {
        if (producto['cantidad'] < 5 && producto['cantidad'] > 0) {
          bajoStock.add(producto);
        }
      });

      bajoStock.sort((a, b) => a['cantidad'].compareTo(b['cantidad']));

      setState(() {
        productosBajoStock = bajoStock;
        productosFiltrados = bajoStock;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar productos bajo stock: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filtrarProductos(String query) {
    setState(() {
      busqueda = query;
      if (query.isEmpty) {
        productosFiltrados = productosBajoStock;
      } else {
        productosFiltrados =
            productosBajoStock
                .where(
                  (p) =>
                      p['nombre'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      p['referencia'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildBusqueda(),
            Expanded(
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4682B4),
                        ),
                      )
                      : productosFiltrados.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 80,
                              color: Color(0xFF4682B4),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '¡Excelente!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4682B4),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No hay productos con stock bajo',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _cargarProductosBajoStock,
                        color: const Color(0xFF4682B4),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: productosFiltrados.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          itemBuilder: (context, index) {
                            final producto = productosFiltrados[index];
                            return _buildProductoCard(producto);
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4682B4), Color(0xFF5a8cc7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Center(
              child: Text(
                'Productos Bajo Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusqueda() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: _filtrarProductos,
        decoration: const InputDecoration(
          hintText: 'Buscar producto o referencia...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Color(0xFF4682B4)),
        ),
      ),
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final cantidad = producto['cantidad'] ?? 0;
    final referencia = producto['referencia'] ?? '';
    final nombre = producto['nombre'] ?? 'Producto sin nombre';

    Color colorCriticidad;
    String nivelCriticidad;

    if (cantidad <= 0) {
      colorCriticidad = Colors.red;
      nivelCriticidad = 'AGOTADO';
    } else if (cantidad <= 3) {
      colorCriticidad = Colors.orange;
      nivelCriticidad = 'CRÍTICO';
    } else {
      colorCriticidad = Colors.yellow.shade700;
      nivelCriticidad = 'BAJO';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Ref: $referencia',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.inventory, size: 16, color: colorCriticidad),
              const SizedBox(width: 4),
              Text(
                '$cantidad uni',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorCriticidad,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorCriticidad.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorCriticidad),
            ),
            child: Text(
              nivelCriticidad,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorCriticidad,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
