import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductosFundirDeskScreen extends StatefulWidget {
  const ProductosFundirDeskScreen({super.key});

  @override
  State<ProductosFundirDeskScreen> createState() =>
      _ProductosFundirDeskScreenState();
}

class _ProductosFundirDeskScreenState extends State<ProductosFundirDeskScreen> {
  String _searchProducto = '';
  DateTime? _selectedDate;

  // Función para marcar producto como completado
  Future<void> _marcarProductoCompletado(String pedidoId, String productoId) async {
    try {
      // Mostrar diálogo de confirmación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Está seguro de marcar este producto como completado?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                ),
                child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener el documento del pedido
      final pedidoDoc = await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .get();

      if (!pedidoDoc.exists) {
        Navigator.of(context).pop(); // Cerrar loading
        _mostrarError('No se encontró el pedido');
        return;
      }

      final pedidoData = pedidoDoc.data()!;
      final productosAFundir = List<Map<String, dynamic>>.from(
        pedidoData['productosAFundir'] ?? []
      );

      // Encontrar y remover el producto completado
      productosAFundir.removeWhere((producto) => producto['id'] == productoId);

      // Actualizar el documento
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .update({
        'productosAFundir': productosAFundir,
      });

      // Cerrar loading
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto marcado como completado'),
          backgroundColor: Color(0xFF27AE60),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Cerrar loading si está abierto
      Navigator.of(context).pop();
      _mostrarError('Error al actualizar: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFE74C3C),
        duration: const Duration(seconds: 3),
      ),
    );
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
                      'Productos a Fundir',
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
                          child: _buildFilters(),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('pedidos')
                                .where('estado', isEqualTo: 'pendiente')
                                .orderBy('fecha', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text('No hay pedidos pendientes.'),
                                );
                              }

                              final allPedidos = snapshot.data!.docs;

                              // Extraer todos los productos a fundir de todos los pedidos
                              List<Map<String, dynamic>> productosAFundir = [];
                              
                              for (var pedido in allPedidos) {
                                final cliente = pedido['cliente'] ?? 'Desconocido';
                                final fecha = pedido['fecha']?.toDate();
                                final productosAFundirArray = pedido['productosAFundir'] as List<dynamic>? ?? [];
                                
                                for (var producto in productosAFundirArray) {
                                  final productoMap = producto as Map<String, dynamic>;
                                  productosAFundir.add({
                                    ...productoMap,
                                    'cliente': cliente,
                                    'fechaPedido': fecha,
                                    'pedidoId': pedido.id,
                                  });
                                }
                              }

                              // Filtrar productos
                              final filteredByProducto = productosAFundir.where((producto) {
                                final nombre = (producto['nombre'] ?? '').toString().toLowerCase();
                                final referencia = (producto['referencia'] ?? '').toString().toLowerCase();
                                final searchTerm = _searchProducto.toLowerCase();
                                return nombre.contains(searchTerm) || referencia.contains(searchTerm);
                              }).toList();

                              final filteredProductos = _selectedDate != null
                                  ? filteredByProducto.where((producto) {
                                      final fecha = producto['fechaPedido'] as DateTime?;
                                      return fecha != null &&
                                          fecha.year == _selectedDate!.year &&
                                          fecha.month == _selectedDate!.month &&
                                          fecha.day == _selectedDate!.day;
                                    }).toList()
                                  : filteredByProducto;

                              if (filteredProductos.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay productos para fundir con los filtros seleccionados.',
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                itemCount: filteredProductos.length,
                                itemBuilder: (context, index) {
                                  final producto = filteredProductos[index];
                                  final nombre = producto['nombre'] ?? 'Sin nombre';
                                  final referencia = producto['referencia'] ?? 'Sin referencia';
                                  final cantidadAFundir = producto['cantidadAFundir'] ?? 0;
                                  final cliente = producto['cliente'] ?? 'Desconocido';
                                  final fecha = producto['fechaPedido'] as DateTime?;
                                  final pedidoId = producto['pedidoId'] ?? '';
                                  final productoId = producto['id'] ?? '';

                                  return Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 14),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          // ✅ CHECKBOX PARA MARCAR COMO COMPLETADO
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            child: InkWell(
                                              onTap: () => _marcarProductoCompletado(pedidoId, productoId),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF27AE60).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(0xFF27AE60).withOpacity(0.3),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.check_circle_outline,
                                                  color: Color(0xFF27AE60),
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE74C3C).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFE74C3C).withOpacity(0.3),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.local_fire_department,
                                              color: Color(0xFFE74C3C),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nombre,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Ref: $referencia',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Cliente: $cliente',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  fecha != null
                                                      ? 'Pedido: ${fecha.day}/${fecha.month}/${fecha.year}'
                                                      : 'Sin fecha',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE74C3C),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'Fundir: $cantidadAFundir',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
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

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por producto o referencia...',
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
          onChanged: (value) {
            setState(() {
              _searchProducto = value;
            });
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _selectedDate == null
                ? 'Filtrar por fecha del pedido'
                : 'Filtrado: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4682B4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_selectedDate != null)
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDate = null;
              });
            },
            child: const Text('Limpiar filtro de fecha'),
          ),
      ],
    );
  }
}