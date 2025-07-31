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
  final Map<String, Map<String, dynamic>> _productosInfo = {};
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

  void _agregarProducto(String id, String nombre, String referencia) {
    setState(() {
      _productosSeleccionados[id] = (_productosSeleccionados[id] ?? 0) + 1;
      _productosInfo[id] = {'nombre': nombre, 'referencia': referencia};
    });
  }

  void _quitarProducto(String id) {
    setState(() {
      _productosSeleccionados[id] = (_productosSeleccionados[id] ?? 0) - 1;
      if (_productosSeleccionados[id]! <= 0) {
        _productosSeleccionados.remove(id);
        _productosInfo.remove(id);
      }
    });
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
      final pedido = {
        'cliente': _clienteController.text,
        'direccion': _direccionController.text,
        'fecha': FieldValue.serverTimestamp(),
        'productos':
            _productosSeleccionados.entries.map((entry) {
              return {
                'id': entry.key,
                'nombre': _productosInfo[entry.key]?['nombre'] ?? '',
                'referencia': _productosInfo[entry.key]?['referencia'] ?? '',
                'cantidad': entry.value,
              };
            }).toList(),
        'estado': 'pendiente',
      };

      await FirebaseFirestore.instance.collection('pedidos').add(pedido);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Limpiar campos después de guardar
        _clienteController.clear();
        _direccionController.clear();
        _buscarController.clear();
        _productosSeleccionados.clear();

        setState(() {}); // Refrescar UI si es necesario
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
                                .collection('inventario_general')
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
                                    child: ListTile(
                                      title: Text(nombre),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ref: $referencia',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
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
                                              },
                                            ),
                                          ],
                                        ),
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
                  ],
                ),
              ),
            ),

            // 📋 DIVISOR
            Container(width: 1, color: Colors.grey.shade300),

            // 🛒 SECCIÓN DERECHA - Resumen del Pedido
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

                    // Lista de productos seleccionados
                    const Text(
                      'Productos:',
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
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                itemCount: _productosSeleccionados.length,
                                itemBuilder: (context, index) {
                                  final id = _productosSeleccionados.keys
                                      .elementAt(index);
                                  final cantidad = _productosSeleccionados[id]!;
                                  final info = _productosInfo[id]!;

                                  return Card(
                                    color:
                                        Colors
                                            .white, // <- ✅ Fondo blanco explícito
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            info['nombre'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text('Ref: ${info['referencia']}'),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Cantidad: $cantidad'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    const SizedBox(height: 24),

                    // 💾 Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardarPedido,
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
          ],
        ),
      ),
    );
  }
}
