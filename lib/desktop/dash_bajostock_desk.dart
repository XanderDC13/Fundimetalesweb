import 'package:basefundi/services/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BajoStockDeskScreen extends StatefulWidget {
  const BajoStockDeskScreen({super.key});

  // Método estático para obtener solo el conteo de productos bajo stock
  static Future<int> obtenerConteoProductosBajoStock() async {
    try {
      final sucursales = ['Quito', 'Guayaquil', 'Tulcán'];
      Map<String, int> stockPorProducto = {};

      // Recorrer todas las sucursales
      for (String sucursal in sucursales) {
        try {
          final inventarioSnapshot =
              await FirebaseFirestore.instance
                  .collection('inventarios')
                  .doc(sucursal)
                  .collection('procesos')
                  .doc('bodega')
                  .collection('productos')
                  .get();

          for (var doc in inventarioSnapshot.docs) {
            final inventarioData = doc.data();
            final cantidad = (inventarioData['cantidad'] ?? 0) as num;
            final referencia = doc.id;

            stockPorProducto[referencia] =
                (stockPorProducto[referencia] ?? 0) + cantidad.toInt();
          }
        } catch (e) {
          print('Error al cargar inventario de $sucursal: $e');
        }
      }

      // Contar productos con stock total menor a 5
      int conteo = 0;
      stockPorProducto.forEach((referencia, cantidadTotal) {
        if (cantidadTotal < 5 && cantidadTotal >= 0) {
          conteo++;
        }
      });

      return conteo;
    } catch (e) {
      print('Error al obtener conteo de productos bajo stock: $e');
      return 0;
    }
  }

  @override
  State<BajoStockDeskScreen> createState() => _BajoStockDeskScreenState();
}

class _BajoStockDeskScreenState extends State<BajoStockDeskScreen> {
  List<Map<String, dynamic>> _allProductos = [];
  List<Map<String, dynamic>> _filteredProductos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductosBajoStock();
  }

  Future<void> _cargarProductosBajoStock() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // ✅ CAMBIO: Obtener TODAS las sucursales
      final sucursales = ['Quito', 'Guayaquil', 'Tulcán'];

      // 2. Consultar colección productos para obtener información del producto
      final productosSnapshot =
          await FirebaseFirestore.instance.collection('productos').get();

      // Crear mapa de productos por referencia para búsqueda rápida
      Map<String, Map<String, dynamic>> productosInfo = {};
      for (var doc in productosSnapshot.docs) {
        final data = doc.data();
        final referencia = data['referencia']?.toString() ?? doc.id;
        productosInfo[referencia] = {
          'nombre': data['nombre'] ?? 'Producto sin nombre',
          'referencia': referencia,
          'categoria': data['categoria'] ?? 'Sin categoría',
        };
      }

      // ✅ MAPA para acumular cantidades de todas las sucursales
      Map<String, int> stockPorProducto = {};

      // ✅ RECORRER todas las sucursales
      for (String sucursal in sucursales) {
        try {
          final inventarioSnapshot =
              await FirebaseFirestore.instance
                  .collection('inventarios')
                  .doc(sucursal)
                  .collection('procesos')
                  .doc('bodega')
                  .collection('productos')
                  .get();

          // Sumar cantidades de esta sucursal
          for (var doc in inventarioSnapshot.docs) {
            final inventarioData = doc.data();
            final cantidad = (inventarioData['cantidad'] ?? 0) as num;
            final referenciaInventario =
                doc.id; // El ID del documento ES la referencia

            // Acumular la cantidad
            stockPorProducto[referenciaInventario] =
                (stockPorProducto[referenciaInventario] ?? 0) +
                cantidad.toInt();
          }
        } catch (e) {
          print('Error al cargar inventario de $sucursal: $e');
        }
      }

      List<Map<String, dynamic>> productosBajoStock = [];

      // ✅ FILTRAR productos con stock total menor a 5
      stockPorProducto.forEach((referencia, cantidadTotal) {
        if (cantidadTotal < 5 && cantidadTotal >= 0) {
          // Buscar información del producto
          final infoProducto =
              productosInfo[referencia] ??
              {
                'nombre': 'Producto sin nombre',
                'referencia': referencia,
                'categoria': 'Sin categoría',
              };

          productosBajoStock.add({
            'id': referencia,
            'nombre': infoProducto['nombre'],
            'referencia': infoProducto['referencia'],
            'cantidad': cantidadTotal,
            'categoria': infoProducto['categoria'],
          });
        }
      });

      // Ordenar por cantidad (menor a mayor)
      productosBajoStock.sort((a, b) => a['cantidad'].compareTo(b['cantidad']));

      setState(() {
        _allProductos = productosBajoStock;
        _filteredProductos = productosBajoStock;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar productos bajo stock: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filtrarProductos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProductos = _allProductos;
      } else {
        _filteredProductos =
            _allProductos.where((producto) {
              final nombre = producto['nombre'].toString().toLowerCase();
              final referencia =
                  producto['referencia'].toString().toLowerCase();
              return nombre.contains(query.toLowerCase()) ||
                  referencia.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Color _getColorCriticidad(int cantidad) {
    if (cantidad <= 0) return Colors.red;
    if (cantidad <= 3) return Colors.orange;
    if (cantidad <= 5) return Colors.yellow.shade700;
    return Colors.blue;
  }

  String _getNivelCriticidad(int cantidad) {
    if (cantidad <= 0) return 'AGOTADO';
    if (cantidad <= 3) return 'CRÍTICO';
    if (cantidad <= 5) return 'BAJO';
    return 'NORMAL';
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA UNIDA Y CENTRADA
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Productos Bajo Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ CONTENIDO CON FONDO BLANCO
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: _buildSearchFilter(),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child:
                              _isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2C3E50),
                                    ),
                                  )
                                  : _filteredProductos.isEmpty
                                  ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          size: 80,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          '¡Excelente!',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50),
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
                                    color: const Color(0xFF2C3E50),
                                    child: GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      itemCount: _filteredProductos.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 1.1,
                                          ),
                                      itemBuilder: (context, index) {
                                        final producto =
                                            _filteredProductos[index];
                                        return _buildProductoCard(producto);
                                      },
                                    ),
                                  ),
                        ),
                      ],
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

  Widget _buildSearchFilter() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar producto o referencia...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: _filtrarProductos,
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final cantidad = producto['cantidad'] ?? 0;
    final referencia = producto['referencia'] ?? '';
    final nombre = producto['nombre'] ?? 'Producto sin nombre';
    final categoria = producto['categoria'] ?? 'Sin categoría';

    final colorCriticidad = _getColorCriticidad(cantidad);
    final nivelCriticidad = _getNivelCriticidad(cantidad);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del producto
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Referencia
            Text(
              'Ref: $referencia',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),

            // Categoría
            Text(
              categoria,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),

            const Spacer(),

            // Stock y nivel de criticidad
            Row(
              children: [
                Icon(Icons.inventory, size: 18, color: colorCriticidad),
                const SizedBox(width: 4),
                Text(
                  '$cantidad uni',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorCriticidad,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Badge de criticidad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorCriticidad.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
