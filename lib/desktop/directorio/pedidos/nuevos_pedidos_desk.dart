import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevosPedidosDeskWidget extends StatefulWidget {
  const NuevosPedidosDeskWidget({super.key});

  @override
  State<NuevosPedidosDeskWidget> createState() => _NuevoPedidoFormState();
}

class _NuevoPedidoFormState extends State<NuevosPedidosDeskWidget> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _buscarController = TextEditingController();
  final Map<String, int> _productosSeleccionados = {};
  String _buscarTexto = '';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _buscarController.addListener(() {
      setState(() {
        _buscarTexto = _buscarController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _direccionController.dispose();
    _buscarController.dispose();
    super.dispose();
  }

  Map<String, ValueNotifier<int>> _notificadoresCantidad = {};

  void _agregarProducto(String id, String nombre, String referencia) {
    _productosSeleccionados.update(id, (value) => value + 1, ifAbsent: () => 1);
    _notificadoresCantidad.putIfAbsent(id, () => ValueNotifier<int>(1)).value =
        _productosSeleccionados[id]!;
  }

  void _quitarProducto(String id) {
    if (_productosSeleccionados.containsKey(id)) {
      final nuevaCantidad = _productosSeleccionados[id]! - 1;
      if (nuevaCantidad <= 0) {
        _productosSeleccionados.remove(id);
        _notificadoresCantidad[id]?.value = 0;
      } else {
        _productosSeleccionados[id] = nuevaCantidad;
        _notificadoresCantidad[id]?.value = nuevaCantidad;
      }
    }
  }

  // Función para obtener cantidades disponibles por referencia
Future<Map<String, int>> _obtenerCantidadesDisponibles(
  String referencia,
) async {
  Map<String, int> cantidades = {
    'bodega': 0,
    'bruto': 0,
    'fundicion': 0,
    'mecanizado': 0,
    'pintura': 0,
    'pulido': 0,
    'total': 0,
    'necesita_fundir': 0, // Para saber si necesita ir a fundición
  };

  try {
    // Lista de todas las subcolecciones a consultar
    final subcolecciones = ['bodega', 'bruto', 'fundicion', 'mecanizado', 'pintura', 'pulido'];

    for (String subcoleccion in subcolecciones) {
      try {
        // Consultar cada subcolección en inventarios/{subcoleccion}/productos/{referencia}
        final docRef = FirebaseFirestore.instance
            .collection('inventarios')
            .doc(subcoleccion)
            .collection('productos')
            .doc(referencia);

        final docSnapshot = await docRef.get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          final cantidad = (data?['cantidad'] ?? 0) as int;
          cantidades[subcoleccion] = cantidad;
        } else {
          cantidades[subcoleccion] = 0;
        }
      } catch (e) {
        print('Error al consultar $subcoleccion para referencia $referencia: $e');
        cantidades[subcoleccion] = 0;
      }
    }

    // Calcular total (suma de todas las subcolecciones)
    cantidades['total'] = cantidades['bodega']! +
        cantidades['bruto']! +
        cantidades['fundicion']! +
        cantidades['mecanizado']! +
        cantidades['pintura']! +
        cantidades['pulido']!;

    // Verificar si necesita mandar a fundir
    // Si el total es 0, necesita fundición
    if (cantidades['total']! == 0) {
      cantidades['necesita_fundir'] = 1;
    } else {
      cantidades['necesita_fundir'] = 0;
    }
    subcolecciones.forEach((proceso) {
      if (cantidades[proceso]! > 0) {
      }
    });

  } catch (e) {
    cantidades.keys.forEach((key) {
      cantidades[key] = key == 'necesita_fundir' ? 1 : 0;
    });
  }

  return cantidades;
}

  Future<void> _guardarPedido() async {
    if (_clienteController.text.isEmpty ||
        _direccionController.text.isEmpty ||
        _productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor complete todos los campos y agregue productos',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final productosIds = _productosSeleccionados.keys.toList();

      // 🔄 Consultar los inventarios
      final snapshots = await Future.wait([
        FirebaseFirestore.instance
            .collection('inventario_general')
            .where(FieldPath.documentId, whereIn: productosIds)
            .get(),
        FirebaseFirestore.instance
            .collection('inventario_fundicion')
            .where(FieldPath.documentId, whereIn: productosIds)
            .get(),
        FirebaseFirestore.instance
            .collection('inventario_pintura')
            .where(FieldPath.documentId, whereIn: productosIds)
            .get(),
      ]);

      final generalDocs = snapshots[0].docs;
      final fundicionDocs = snapshots[1].docs;
      final pinturaDocs = snapshots[2].docs;

      final generalMap = {for (var doc in generalDocs) doc.id: doc.data()};
      final fundicionMap = {for (var doc in fundicionDocs) doc.id: doc.data()};
      final pinturaMap = {for (var doc in pinturaDocs) doc.id: doc.data()};

      List<Map<String, dynamic>> productosCompletos = [];
      List<Map<String, dynamic>> productosAFundir = [];

      for (final id in productosIds) {
        final cantidadSolicitada = _productosSeleccionados[id] ?? 0;
        final dataGeneral = generalMap[id];
        final dataFundicion = fundicionMap[id];
        final dataPintura = pinturaMap[id];

        final nombre =
            dataGeneral?['nombre'] ??
            dataFundicion?['nombre'] ??
            dataPintura?['nombre'] ??
            'Producto';
        final referencia =
            dataGeneral?['referencia'] ??
            dataFundicion?['referencia'] ??
            dataPintura?['referencia'] ??
            '';

        // 🔄 Obtener stock real de las tres colecciones usando la referencia
        final cantidadesDisponibles = await _obtenerCantidadesDisponibles(
          referencia,
        );
        final stockTotal = cantidadesDisponibles['total'] ?? 0;

        productosCompletos.add({
          'id': id,
          'nombre': nombre,
          'referencia': referencia,
          'cantidad': cantidadSolicitada,
        });

        // 🔍 CORRECCIÓN: Solo agregar a productosAFundir si el stock es insuficiente
        if (stockTotal < cantidadSolicitada) {
          final cantidadAFundir = cantidadSolicitada - stockTotal;

          productosAFundir.add({
            'id': id,
            'nombre': nombre,
            'referencia': referencia,
            'cantidadAFundir': cantidadAFundir, // Solo la cantidad que falta
            'cantidadSolicitada':
                cantidadSolicitada, // Cantidad total solicitada
            'stockDisponible': stockTotal, // Stock disponible actual
            'stockFundicion': cantidadesDisponibles['fundicion'] ?? 0,
            'stockPintura': cantidadesDisponibles['pintura'] ?? 0,
            'stockHistorial': cantidadesDisponibles['historial'] ?? 0,
          });
        }
      }

      final pedido = {
        'cliente': _clienteController.text,
        'direccion': _direccionController.text,
        'fecha': FieldValue.serverTimestamp(),
        'productos': productosCompletos,
        'productosAFundir':
            productosAFundir, // Solo productos con stock insuficiente
        'estado': 'pendiente',
      };

      await FirebaseFirestore.instance.collection('pedidos').add(pedido);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              productosAFundir.isNotEmpty
                  ? 'Pedido guardado. ${productosAFundir.length} producto(s) requieren fundición.'
                  : 'Pedido guardado exitosamente',
            ),
            backgroundColor:
                productosAFundir.isNotEmpty ? Colors.orange : Colors.green,
          ),
        );

        _clienteController.clear();
        _direccionController.clear();
        _buscarController.clear();
        _productosSeleccionados.clear();

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1200,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🎯 SECCIÓN IZQUIERDA - Crear Pedido
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔵 Ícono y texto en la misma línea
                    Row(
                      children: [
                        const Icon(
                          Icons.move_to_inbox,
                          size: 28,
                          color: Color(0xFF4682B4),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Nuevo Pedido',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 🧑 Campos nombre del cliente y dirección en la misma línea
                    Row(
                      children: [
                        // Campo nombre del cliente (más pequeño)
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _clienteController,
                              style: const TextStyle(fontSize: 16),
                              onChanged: (value) {
                                setState(
                                  () {},
                                ); // Actualizar resumen en tiempo real
                              },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                labelText: 'Nombre del Cliente',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Campo dirección (más grande)
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _direccionController,
                              style: const TextStyle(fontSize: 16),
                              onChanged: (value) {
                                setState(
                                  () {},
                                ); // Actualizar resumen en tiempo real
                              },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                labelText: 'Dirección',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔍 Campo de búsqueda
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _buscarController,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintText: 'Buscar producto por nombre o referencia',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 📦 Lista de productos
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('productos')
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
                            return const Text('No hay productos disponibles.');
                          }

                          // 👇 Evitamos reconstrucción innecesaria
                          final productosFiltrados =
                              snapshot.data!.docs.where((doc) {
                                final nombre =
                                    (doc['nombre'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                final referencia =
                                    (doc['referencia'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                return nombre.contains(_buscarTexto) ||
                                    referencia.contains(_buscarTexto);
                              }).toList();

                          return ListView.builder(
                            itemCount: productosFiltrados.length,
                            itemBuilder: (context, index) {
                              final doc = productosFiltrados[index];
                              final nombre = doc['nombre'] ?? 'Sin nombre';
                              final referencia = doc['referencia'] ?? '—';
                              final id = doc.id;

                              return StatefulBuilder(
                                builder: (context, setInnerState) {
                                  return Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ExpansionTile(
                                      title: Text(nombre),
                                      subtitle: Text(
                                        'Ref: $referencia',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: SizedBox(
                                        width: 120,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed:
                                                  _productosSeleccionados
                                                          .containsKey(id)
                                                      ? () {
                                                        _quitarProducto(id);
                                                        setInnerState(() {});
                                                        setState(
                                                          () {},
                                                        ); // Actualizar resumen
                                                      }
                                                      : null,
                                            ),
                                            Container(
                                              width: 30,
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${_productosSeleccionados[id] ?? 0}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              onPressed: () {
                                                _agregarProducto(
                                                  id,
                                                  nombre,
                                                  referencia,
                                                );
                                                setInnerState(() {});
                                                setState(
                                                  () {},
                                                ); // Actualizar resumen
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      children: [
                                        // Mostrar inventarios disponibles
                                        FutureBuilder<Map<String, int>>(
                                          future: _obtenerCantidadesDisponibles(
                                            referencia,
                                          ),
                                          builder: (
                                            context,
                                            cantidadesSnapshot,
                                          ) {
                                            if (cantidadesSnapshot
                                                    .connectionState ==
                                                ConnectionState.waiting) {
                                              return const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }

                                            if (!cantidadesSnapshot.hasData) {
                                              return const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Text(
                                                  'Error al cargar inventarios',
                                                ),
                                              );
                                            }

                                            final cantidades =
                                                cantidadesSnapshot.data!;

                                            return Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Inventarios Disponibles:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      _buildInventarioChip(
                                                        'Fundición',
                                                        cantidades['fundicion']!,
                                                        const Color(0xFF4682B4),
                                                      ),
                                                      _buildInventarioChip(
                                                        'Pintura',
                                                        cantidades['pintura']!,
                                                        const Color(0xFF4682B4),
                                                      ),
                                                      _buildInventarioChip(
                                                        'General',
                                                        cantidades['historial']!,
                                                        const Color(0xFF4682B4),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade300,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Text(
                                                          'Total Disponible: ',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${cantidades['total']} unidades',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                cantidades['total']! >
                                                                        0
                                                                    ? Colors
                                                                        .green[700]
                                                                    : Colors
                                                                        .red[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
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

            // 📋 DIVISOR 1
            Container(width: 1, color: Colors.grey.shade300),

            // 🛒 SECCIÓN CENTRAL - Resumen del Pedido
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          size: 24,
                          color: Color(0xFF4682B4),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Resumen del Pedido',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Información del cliente y dirección
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Cliente: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  _clienteController.text.isEmpty
                                      ? 'Sin especificar'
                                      : _clienteController.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Dirección: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  _direccionController.text.isEmpty
                                      ? 'Sin especificar'
                                      : _direccionController.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Productos en Stock:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child:
                          _productosSeleccionados.isEmpty
                              ? const Center(
                                child: Text(
                                  'No hay productos seleccionados',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('productos')
                                        .where(
                                          FieldPath.documentId,
                                          whereIn:
                                              _productosSeleccionados.keys
                                                  .toList(),
                                        )
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
                                      child: Text(
                                        'Error al cargar productos seleccionados',
                                      ),
                                    );
                                  }

                                  return FutureBuilder<
                                    List<Map<String, dynamic>>
                                  >(
                                    future: _analizarInventarioProductosResumen(
                                      snapshot.data!.docs,
                                    ),
                                    builder: (context, inventarioSnapshot) {
                                      if (inventarioSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final productosConInventario =
                                          inventarioSnapshot.data ?? [];

                                      // Filtrar solo productos con stock suficiente
                                      final productosConStock =
                                          productosConInventario
                                              .where(
                                                (p) =>
                                                    p['totalDisponible'] >=
                                                    _productosSeleccionados[p['id']]!,
                                              )
                                              .toList();

                                      if (productosConStock.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No hay productos con stock suficiente',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: productosConStock.length,
                                        itemBuilder: (context, index) {
                                          final p = productosConStock[index];
                                          final id = p['id'];
                                          final nombre = p['nombre'];
                                          final referencia = p['referencia'];
                                          final cantidad =
                                              _productosSeleccionados[id] ?? 0;

                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            color: Colors.green.shade50,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green[600],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          nombre,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          'Ref: $referencia',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$cantidad',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.green[600],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (_guardando || _productosSeleccionados.isEmpty)
                                ? null
                                : _guardarPedido,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _guardando
                                ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Guardando...'),
                                  ],
                                )
                                : const Text(
                                  'Guardar Pedido',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 📋 DIVISOR 2
            Container(width: 1, color: Colors.grey.shade300),

            // 🔥 SECCIÓN DERECHA - Productos a Mandar a Fundir
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.whatshot,
                          size: 24,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'A Mandar a Fundir',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child:
                          _productosSeleccionados.isEmpty
                              ? const Center(
                                child: Text(
                                  'No hay productos seleccionados',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('productos')
                                        .where(
                                          FieldPath.documentId,
                                          whereIn:
                                              _productosSeleccionados.keys
                                                  .toList(),
                                        )
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
                                      child: Text(
                                        'Error al cargar productos seleccionados',
                                      ),
                                    );
                                  }

                                  return FutureBuilder<
                                    List<Map<String, dynamic>>
                                  >(
                                    future: _analizarInventarioProductosResumen(
                                      snapshot.data!.docs,
                                    ),
                                    builder: (context, inventarioSnapshot) {
                                      if (inventarioSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final productosConInventario =
                                          inventarioSnapshot.data ?? [];

                                      // Filtrar solo productos sin stock suficiente
                                      final productosSinStock =
                                          productosConInventario
                                              .where(
                                                (p) =>
                                                    p['totalDisponible'] <
                                                    _productosSeleccionados[p['id']]!,
                                              )
                                              .toList();

                                      if (productosSinStock.isEmpty) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 48,
                                                color: Colors.green,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                '¡Perfecto!',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Todos los productos tienen stock suficiente',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: [
                                          // Header con información
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              border: Border.all(
                                                color: Colors.orange.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning,
                                                  color: Colors.orange[700],
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${productosSinStock.length} producto${productosSinStock.length > 1 ? 's' : ''} necesita${productosSinStock.length > 1 ? 'n' : ''} fundición',
                                                  style: TextStyle(
                                                    color: Colors.orange[700],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Lista de productos sin stock
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount:
                                                  productosSinStock.length,
                                              itemBuilder: (context, index) {
                                                final p =
                                                    productosSinStock[index];
                                                final id = p['id'];
                                                final nombre = p['nombre'];
                                                final referencia =
                                                    p['referencia'];
                                                final cantidadSolicitada =
                                                    _productosSeleccionados[id] ??
                                                    0;
                                                final totalDisponible =
                                                    p['totalDisponible'];
                                                final cantidadAFundir =
                                                    cantidadSolicitada -
                                                    totalDisponible;

                                                return Card(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 3,
                                                      ),
                                                  color: Colors.orange.shade50,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.fire_truck,
                                                              color:
                                                                  Colors
                                                                      .orange[600],
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                nombre,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'Ref: $referencia',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  Colors
                                                                      .orange
                                                                      .shade200,
                                                            ),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    'A Fundir:',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      color:
                                                                          Colors
                                                                              .orange[700],
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    '$cantidadAFundir',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          Colors
                                                                              .orange[700],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
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
          ],
        ),
      ),
    );
  }

  // Método para analizar inventario de productos en el resumen
  Future<List<Map<String, dynamic>>> _analizarInventarioProductosResumen(
    List<QueryDocumentSnapshot> docs,
  ) async {
    List<Map<String, dynamic>> productosConInventario = [];

    for (final doc in docs) {
      final id = doc.id;
      final nombre = doc['nombre'] ?? 'Sin nombre';
      final referencia = doc['referencia'] ?? '—';

      // Obtener cantidades disponibles
      final cantidades = await _obtenerCantidadesDisponibles(referencia);
      final totalDisponible = cantidades['total'] ?? 0;

      productosConInventario.add({
        'id': id,
        'nombre': nombre,
        'referencia': referencia,
        'totalDisponible': totalDisponible,
        'fundicion': cantidades['fundicion'] ?? 0,
        'pintura': cantidades['pintura'] ?? 0,
        'historial': cantidades['historial'] ?? 0,
      });
    }

    return productosConInventario;
  }

  // Widget helper para mostrar chips de inventario
  Widget _buildInventarioChip(String label, int cantidad, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            cantidad.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
