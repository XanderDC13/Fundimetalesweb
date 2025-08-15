import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlistarPedidosDeskWidget extends StatefulWidget {
  const AlistarPedidosDeskWidget({super.key});

  @override
  State<AlistarPedidosDeskWidget> createState() =>
      _AlistarPedidosDeskWidgetState();
}

class _AlistarPedidosDeskWidgetState extends State<AlistarPedidosDeskWidget> {
  final Map<String, TextEditingController> _observacionesControllers = {};
  final Map<String, bool> _expandedPedidos = {};

  @override
  void dispose() {
    for (var controller in _observacionesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getObservacionController(String pedidoId) {
    if (!_observacionesControllers.containsKey(pedidoId)) {
      _observacionesControllers[pedidoId] = TextEditingController();
    }
    return _observacionesControllers[pedidoId]!;
  }

  Future<void> _toggleProductoCompletado(
    String pedidoId,
    int productoIndex,
    bool completado,
  ) async {
    try {
      final pedidoRef = FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId);
      final pedidoDoc = await pedidoRef.get();

      if (pedidoDoc.exists) {
        List<dynamic> productos = List.from(pedidoDoc.data()!['productos']);
        productos[productoIndex]['completado'] = completado;

        await pedidoRef.update({'productos': productos});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar producto: $e')),
        );
      }
    }
  }

  Future<void> _completarPedido(String pedidoId) async {
    try {
      final observacion = _getObservacionController(pedidoId).text;

      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .update({
            'estado': 'alistado',
            'observaciones_alistamiento': observacion,
            'fecha_alistamiento': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido completado y enviado a la sección de envíos'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _observacionesControllers.remove(pedidoId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _todosProdutosCompletados(List<dynamic> productos) {
    return productos.every((producto) => producto['completado'] == true);
  }

  int _productosCompletados(List<dynamic> productos) {
    return productos.where((producto) => producto['completado'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist, size: 28, color: Color(0xFF4682B4)),
              const SizedBox(width: 8),
              const Text(
                'Pedidos por Alistar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('pedidos')
                        .where('estado', isEqualTo: 'pendiente')
                        .snapshots(),
                builder: (context, snapshot) {
                  final count =
                      snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4682B4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count pendientes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('pedidos')
                      .where('estado', isEqualTo: 'pendiente')
                      .orderBy('fecha', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Error al cargar pedidos: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay pedidos pendientes por alistar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final pedidoId = doc.id;
                    final cliente = doc['cliente'] ?? 'Cliente sin nombre';
                    final direccion = doc['direccion'] ?? 'Sin dirección';
                    final productos = List<dynamic>.from(
                      doc['productos'] ?? [],
                    );
                    final fecha = doc['fecha'] as Timestamp?;

                    for (var producto in productos) {
                      producto['completado'] ??= false;
                    }

                    final productosCompletados = _productosCompletados(
                      productos,
                    );
                    final todosCompletados = _todosProdutosCompletados(
                      productos,
                    );
                    final isExpanded = _expandedPedidos[pedidoId] ?? false;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              todosCompletados
                                  ? Colors.green
                                  : Colors.grey.shade300,
                          width: todosCompletados ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  todosCompletados
                                      ? const Color(0xFF4682B4)
                                      : const Color(0xFF4682B4),
                              child: Icon(
                                todosCompletados ? Icons.check : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              cliente,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dirección agregada aquí
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        direccion,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (fecha != null)
                                  Text(
                                    'Fecha: ${fecha.toDate().day}/${fecha.toDate().month}/${fecha.toDate().year} ${fecha.toDate().hour}:${fecha.toDate().minute.toString().padLeft(2, '0')}',
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            todosCompletados
                                                ? Colors.green
                                                : const Color(0xFF4682B4),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$productosCompletados/${productos.length} productos',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (todosCompletados)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'LISTO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  _expandedPedidos[pedidoId] = !isExpanded;
                                });
                              },
                            ),
                          ),
                          if (isExpanded) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Productos a alistar:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...productos.asMap().entries.map((entry) {
                                    final int productoIndex = entry.key;
                                    final producto = entry.value;
                                    final completado =
                                        producto['completado'] ?? false;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            completado
                                                ? Colors.green.shade50
                                                : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              completado
                                                  ? Colors.green.shade200
                                                  : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: completado,
                                            onChanged: (value) {
                                              _toggleProductoCompletado(
                                                pedidoId,
                                                productoIndex,
                                                value ?? false,
                                              );
                                            },
                                            activeColor: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  producto['nombre'] ??
                                                      'Producto sin nombre',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    decoration:
                                                        completado
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                    color:
                                                        completado
                                                            ? Colors.grey
                                                            : null,
                                                  ),
                                                ),
                                                Text(
                                                  'Ref: ${producto['referencia'] ?? '—'} | Cantidad: ${producto['cantidad']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    decoration:
                                                        completado
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  if (doc['productosAFundir'] != null &&
                                      doc['productosAFundir'].isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Productos que necesitan fundición:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List<Widget>.from(
                                      doc['productosAFundir'].map<Widget>((
                                        producto,
                                      ) {
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  producto['nombre'] ??
                                                      'Sin nombre',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'Ref: ${producto['referencia'] ?? '—'}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'A fundir: ${producto['cantidadAFundir']}',
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],

                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _getObservacionController(
                                      pedidoId,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Observaciones (opcional)',
                                      hintText:
                                          'Ej: Producto empacado con cuidado extra',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.note_add),
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          todosCompletados
                                              ? () => _completarPedido(pedidoId)
                                              : null,
                                      icon: const Icon(Icons.check_circle),
                                      label: Text(
                                        todosCompletados
                                            ? 'Completar Pedido y Enviar a Despacho'
                                            : 'Complete todos los productos para continuar',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            todosCompletados
                                                ? Colors.green
                                                : Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
