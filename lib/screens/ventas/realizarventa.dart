import 'package:basefundi/screens/ventas/carrito.dart';
import 'package:basefundi/screens/ventas/carrito_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class VentasDetalleScreen extends StatefulWidget {
  const VentasDetalleScreen({super.key});

  @override
  State<VentasDetalleScreen> createState() => _VentasDetalleScreenState();
}

class _VentasDetalleScreenState extends State<VentasDetalleScreen> {
  String searchQuery = '';

  void _startScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );

    if (result is String) {
      setState(() {
        searchQuery = result;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductosCombinados() async {
    final historialSnapshot =
        await FirebaseFirestore.instance
            .collection('historial_inventario_general')
            .orderBy('fecha_actualizacion', descending: true)
            .get();

    final inventarioSnapshot =
        await FirebaseFirestore.instance.collection('inventario_general').get();

    final ventasSnapshot =
        await FirebaseFirestore.instance.collection('ventas').get();

    final Map<String, Map<String, dynamic>> baseProductos = {};
    for (var doc in inventarioSnapshot.docs) {
      final data = doc.data();
      final codigo = (data['codigo'] ?? '').toString();
      baseProductos[codigo] = {
        'codigo': codigo,
        'nombre': data['nombre'] ?? '',
        'precios': (data['precios'] ?? []),
        'cantidad': 0,
      };
    }

    for (var doc in historialSnapshot.docs) {
      final data = doc.data();
      final codigo = (data['codigo'] ?? '').toString();
      final cantidad = (data['cantidad'] ?? 0) as int;
      final tipo = (data['tipo'] ?? 'entrada').toString();
      final ajuste = tipo == 'salida' ? -cantidad : cantidad;

      if (baseProductos.containsKey(codigo)) {
        baseProductos[codigo]!['cantidad'] += ajuste;
      } else {
        baseProductos[codigo] = {
          'codigo': codigo,
          'nombre': data['nombre'] ?? '',
          'precio': 0.0,
          'PVP1': 0.0,
          'PVP2': 0.0,
          'PVP3': 0.0,
          'PVP4': 0.0,
          'PVP5': 0.0,
          'PVP6': 0.0,
          'cantidad': ajuste,
        };
      }
    }

    for (var venta in ventasSnapshot.docs) {
      final productos = List<Map<String, dynamic>>.from(venta['productos']);
      for (var producto in productos) {
        final codigo = producto['codigo']?.toString() ?? '';
        final cantidad = (producto['cantidad'] ?? 0) as num;

        if (baseProductos.containsKey(codigo)) {
          baseProductos[codigo]!['cantidad'] -= cantidad.toInt();
        }
      }
    }

    return baseProductos.values.toList();
  }

  Future<void> _seleccionarPrecioYAgregar(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final List<dynamic> precios = data['precios'] ?? [];

    if (precios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay precios configurados')),
      );
      return;
    }

    final precioSeleccionado = await showModalBottomSheet<double>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona un precio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...precios.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final precio = (entry.value as num).toDouble();
                return ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text('PVP$index: \$ ${precio.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.pop(context, precio);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );

    if (precioSeleccionado != null) {
      final producto = ProductoEnCarrito(
        codigo: data['codigo'],
        nombre: data['nombre'],
        precio: precioSeleccionado,
        disponibles: data['cantidad'],
      );

      try {
        Provider.of<CarritoController>(
          context,
          listen: false,
        ).agregarProducto(producto);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data['nombre']} agregado al carrito')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes unidades disponibles')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4682B4),
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: const Text('Ver Carrito', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerCarritoScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
              width: double.infinity,
              child: const Center(
                child: Text(
                  'Realizar Venta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o código',
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 30),
                    onPressed: _startScanner,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchProductosCombinados(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final productos = snapshot.data ?? [];

                  final filtered =
                      productos.where((data) {
                        final nombre = data['nombre'].toString().toLowerCase();
                        final codigo = data['codigo'].toString().toLowerCase();
                        return searchQuery.isEmpty ||
                            nombre.contains(searchQuery.toLowerCase()) ||
                            codigo.contains(searchQuery.toLowerCase());
                      }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No hay productos disponibles.'),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.90,
                      children:
                          filtered
                              .map((data) => _buildProductoCard(data, context))
                              .toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> data, BuildContext context) {
    return GestureDetector(
      onTap: () {
        _seleccionarPrecioYAgregar(data, context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_rounded,
              size: 40,
              color: Color(0xFF2C3E50),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                data['nombre'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${data['cantidad']} disponibles',
              style: const TextStyle(fontSize: 13, color: Color(0xFFB0BEC5)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Agregar',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                onPressed: () {
                  _seleccionarPrecioYAgregar(data, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
