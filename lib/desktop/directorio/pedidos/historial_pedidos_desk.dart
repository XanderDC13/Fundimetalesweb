import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistorialEnviosDeskScreen extends StatefulWidget {
  const HistorialEnviosDeskScreen({super.key});

  @override
  State<HistorialEnviosDeskScreen> createState() =>
      _HistorialEnviosDeskScreenState();
}

class _HistorialEnviosDeskScreenState extends State<HistorialEnviosDeskScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _searchCliente = '';

  Future<void> _seleccionarFecha({required bool esInicio}) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fechaSeleccionada;
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
    }
  }

  Stream<QuerySnapshot> _obtenerEnvios() {
    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .where('estado', isEqualTo: 'enviado')
        .orderBy('fecha_envio', descending: true);

    if (_fechaInicio != null) {
      query = query.where(
        'fecha_envio',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
      );
    }
    if (_fechaFin != null) {
      query = query.where(
        'fecha_envio',
        isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
      );
    }

    return query.snapshots();
  }

  void _mostrarDetalleProductos(Map<String, dynamic> pedido) {
    final cliente = pedido['cliente'] ?? 'Sin nombre';
    final direccion = pedido['direccion'] ?? 'Sin dirección';
    final observaciones = pedido['observaciones_alistamiento'];
    final productos = pedido['productos'] as List? ?? [];

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              color: Colors.white,
              width: 600,
              constraints: const BoxConstraints(maxHeight: 700),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 28,
                        color: Color(0xFF4682B4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalle del Envío',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Pedido enviado',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Información del cliente y dirección
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 20,
                              color: Color(0xFF4682B4),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Cliente: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                cliente,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 20,
                              color: Color(0xFF4682B4),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Dirección: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                direccion,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lista de productos
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Productos enviados (${productos.length}):',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...productos.map((producto) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          producto['nombre'] ??
                                              'Producto sin nombre',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Ref: ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              producto['referencia'] ?? '—',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Cantidad: ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${producto['cantidad']}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          // Observaciones si existen
                          if (observaciones != null &&
                              observaciones.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Observaciones del alistamiento:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.note,
                                    size: 20,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      observaciones,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón cerrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

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
                      'Historial de Envíos',
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
                            stream: _obtenerEnvios(),
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
                                  child: Text('No hay envíos en este rango.'),
                                );
                              }

                              final allPedidos = snapshot.data!.docs;

                              // Filtrar por cliente
                              final filteredPedidos =
                                  allPedidos.where((pedido) {
                                    final data =
                                        pedido.data() as Map<String, dynamic>;
                                    final cliente =
                                        (data['cliente'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                    return cliente.contains(
                                      _searchCliente.toLowerCase(),
                                    );
                                  }).toList();

                              if (filteredPedidos.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay resultados para los filtros seleccionados.',
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                itemCount: filteredPedidos.length,
                                itemBuilder: (context, index) {
                                  final pedido =
                                      filteredPedidos[index].data()
                                          as Map<String, dynamic>;
                                  final cliente =
                                      pedido['cliente'] ?? 'Sin nombre';
                                  final direccion =
                                      pedido['direccion'] ?? 'Sin dirección';
                                  final fechaEnvio =
                                      (pedido['fecha_envio'] as Timestamp?)
                                          ?.toDate();
                                  final productos =
                                      pedido['productos'] as List? ?? [];

                                  return GestureDetector(
                                    onTap:
                                        () => _mostrarDetalleProductos(pedido),
                                    child: Card(
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
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.local_shipping,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cliente,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          direccion,
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.black54,
                                                            fontSize: 13,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${productos.length} producto(s) enviado(s)',
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    fechaEnvio != null
                                                        ? dateFormat.format(
                                                          fechaEnvio,
                                                        )
                                                        : 'Fecha desconocida',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ],
                                        ),
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
        // Campo de búsqueda por cliente
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por cliente...',
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
              _searchCliente = value;
            });
          },
        ),
        const SizedBox(height: 10),

        // Filtros de fecha
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _seleccionarFecha(esInicio: true),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _fechaInicio == null
                      ? 'Fecha inicio'
                      : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _seleccionarFecha(esInicio: false),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _fechaFin == null
                      ? 'Fecha fin'
                      : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Botón para limpiar filtros
        if (_fechaInicio != null || _fechaFin != null)
          TextButton(
            onPressed: () {
              setState(() {
                _fechaInicio = null;
                _fechaFin = null;
              });
            },
            child: const Text('Limpiar filtros de fecha'),
          ),
      ],
    );
  }
}
