import 'package:basefundi/services/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KardexDetailScreen extends StatefulWidget {
  final String referencia;
  final String nombre;

  const KardexDetailScreen({
    super.key,
    required this.referencia,
    required this.nombre,
  });

  @override
  State<KardexDetailScreen> createState() => _KardexDetailScreenState();
}

class _KardexDetailScreenState extends State<KardexDetailScreen> {
  DateTime? fechaInicio;
  DateTime? fechaFin;
  String tipoFiltro = 'Todos';
  String sucursalFiltro = 'Todas'; // ← NUEVO

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          fechaInicio != null && fechaFin != null
              ? DateTimeRange(start: fechaInicio!, end: fechaFin!)
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4682B4),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        fechaInicio = picked.start;
        fechaFin = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      fechaInicio = null;
      fechaFin = null;
      tipoFiltro = 'Todos';
      sucursalFiltro = 'Todas'; // ← NUEVO
    });
  }

  Future<void> _confirmarEliminarMovimiento(String movimientoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Eliminar movimiento'),
            content: const Text(
              '¿Estás seguro de eliminar este movimiento del kardex?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection('kardex_movimientos')
            .doc(movimientoId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editarCantidad(String movimientoId, int cantidadActual) async {
    final TextEditingController controller = TextEditingController(
      text: cantidadActual.toString(),
    );

    final nuevaCantidad = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Editar cantidad'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nueva cantidad',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final valor = int.tryParse(controller.text);
                  if (valor != null && valor > 0) {
                    Navigator.pop(context, valor);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (nuevaCantidad != null) {
      try {
        await FirebaseFirestore.instance
            .collection('kardex_movimientos')
            .doc(movimientoId)
            .update({'cantidad': nuevaCantidad});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cantidad actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // Header
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.nombre,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ref: ${widget.referencia}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ← NUEVO: Filtro de sucursal
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<String>(
                    value: sucursalFiltro,
                    isExpanded: true,
                    underline: Container(),
                    icon: const Icon(
                      Icons.location_on,
                      color: Color(0xFF4682B4),
                    ),
                    items:
                        ['Todas', 'Guayaquil', 'Quito', 'Tulcán'].map((s) {
                          return DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          );
                        }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        sucursalFiltro = valor!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Filtro de tipo
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<String>(
                    value: tipoFiltro,
                    isExpanded: true,
                    underline: Container(),
                    icon: const Icon(
                      Icons.filter_list,
                      color: Color(0xFF4682B4),
                    ),
                    items:
                        [
                          'Todos',
                          'entrada',
                          'salida',
                          'rechazo',
                          'movimiento',
                        ].map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(
                              tipo == 'Todos' ? tipo : tipo.toUpperCase(),
                            ),
                          );
                        }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        tipoFiltro = valor!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Botones de filtro de fecha
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4682B4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          fechaInicio != null
                              ? '${DateFormat('dd/MM/yy').format(fechaInicio!)} - ${DateFormat('dd/MM/yy').format(fechaFin!)}'
                              : 'Filtrar por fecha',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _seleccionarRangoFechas,
                      ),
                    ),
                    if (fechaInicio != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: _limpiarFiltros,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tabla de movimientos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: () {
                // ← NUEVO: query con filtro de sucursal igual que mobile
                Query query = FirebaseFirestore.instance
                    .collection('kardex_movimientos')
                    .where('referencia', isEqualTo: widget.referencia);

                if (sucursalFiltro != 'Todas') {
                  query = query.where('sucursal', isEqualTo: sucursalFiltro);
                }

                return query.orderBy('fecha', descending: true).snapshots();
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay movimientos registrados',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Aplicar filtros
                var movimientos =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final tipo = data['tipo'] as String;
                      final fecha = (data['fecha'] as Timestamp).toDate();

                      if (tipoFiltro != 'Todos' && tipo != tipoFiltro) {
                        return false;
                      }

                      if (fechaInicio != null && fechaFin != null) {
                        if (fecha.isBefore(fechaInicio!) ||
                            fecha.isAfter(fechaFin!)) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                // ← CORREGIDO: igual que mobile, incluye inventario_inicial en entradas
                int totalEntradas = 0;
                int totalSalidas = 0;
                int totalRechazos = 0;

                for (var doc in movimientos) {
                  final data = doc.data() as Map<String, dynamic>;
                  final tipo = data['tipo'] as String;
                  final cantidad = (data['cantidad'] ?? 0) as int;

                  if (tipo == 'inventario_inicial' || tipo == 'entrada') {
                    totalEntradas += cantidad;
                  } else if (tipo == 'salida') {
                    totalSalidas += cantidad;
                  } else if (tipo == 'rechazo') {
                    totalRechazos += cantidad;
                  }
                }

                final saldoActual =
                    totalEntradas - totalSalidas - totalRechazos;

                return Column(
                  children: [
                    // Tarjetas de totales
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTotalCard(
                              'Entradas',
                              totalEntradas,
                              Icons.arrow_upward,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTotalCard(
                              'Salidas',
                              totalSalidas,
                              Icons.arrow_downward,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTotalCard(
                              'Rechazos',
                              totalRechazos,
                              Icons.cancel,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Saldo actual
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: saldoActual > 0 ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SALDO ACTUAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$saldoActual',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tabla
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          child: Builder(
                            builder: (context) {
                              // Agrupar movimientos
                              Map<String, Map<String, dynamic>> agrupados = {};

                              for (var doc in movimientos) {
                                final data = doc.data() as Map<String, dynamic>;
                                final tipo = data['tipo'] as String;
                                final cantidad = (data['cantidad'] ?? 0) as int;
                                final fecha =
                                    (data['fecha'] as Timestamp).toDate();
                                final motivo = data['motivo'] ?? '';
                                final sucursal = data['sucursal'] ?? '';

                                String clave =
                                    '${dateFormat.format(fecha)}_${tipo}_${motivo}_${sucursal}';

                                if (agrupados.containsKey(clave)) {
                                  agrupados[clave]!['cantidad'] += cantidad;
                                  agrupados[clave]!['ids'].add(doc.id);
                                } else {
                                  agrupados[clave] = {
                                    'id': doc.id,
                                    'ids': [doc.id],
                                    'fecha': fecha,
                                    'tipo': tipo,
                                    'cantidad': cantidad,
                                    'motivo': motivo,
                                    'sucursal': sucursal,
                                  };
                                }
                              }

                              // Ordenar por fecha (del más antiguo al más reciente)
                              List<Map<String, dynamic>> filasOrdenadas =
                                  agrupados.values.toList()..sort(
                                    (a, b) => (a['fecha'] as DateTime)
                                        .compareTo(b['fecha'] as DateTime),
                                  );

                              // ← CORREGIDO: igual que mobile, incluye inventario_inicial en saldo acumulado
                              int saldoAcumulado = 0;

                              for (var fila in filasOrdenadas) {
                                if (fila['tipo'] == 'inventario_inicial' ||
                                    fila['tipo'] == 'entrada') {
                                  saldoAcumulado += fila['cantidad'] as int;
                                } else if (fila['tipo'] == 'salida' ||
                                    fila['tipo'] == 'rechazo') {
                                  saldoAcumulado -= fila['cantidad'] as int;
                                }
                                fila['saldo'] = saldoAcumulado;
                              }

                              return DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFF4682B4).withOpacity(0.1),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'FECHA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'DETALLE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'INVENTARIO\nINICIAL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'ENTRADAS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'SALIDAS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'SALDO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'ACCIONES',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: () {
                                  final filasReversed =
                                      filasOrdenadas.reversed.toList();
                                  return List.generate(filasReversed.length, (
                                    index,
                                  ) {
                                    Map<String, dynamic> fila =
                                        filasReversed[index];

                                    int inventarioInicial = 0;
                                    int indexAnteriorEnTiempo =
                                        filasOrdenadas.length - 1 - index - 1;
                                    if (indexAnteriorEnTiempo >= 0) {
                                      inventarioInicial =
                                          filasOrdenadas[indexAnteriorEnTiempo]['saldo']
                                              as int;
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            dateFormat.format(fila['fecha']),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 180,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (fila['sucursal'].isNotEmpty)
                                                  Text(
                                                    fila['sucursal'],
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                if (fila['motivo'].isNotEmpty)
                                                  Text(
                                                    fila['motivo'],
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // ← CORREGIDO: igual que mobile, muestra cantidad si es inventario_inicial
                                        DataCell(
                                          Center(
                                            child: Text(
                                              fila['tipo'] ==
                                                      'inventario_inicial'
                                                  ? '${fila['cantidad']}'
                                                  : '$inventarioInicial',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              fila['tipo'] == 'entrada'
                                                  ? '${fila['cantidad']}'
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              fila['tipo'] == 'salida' ||
                                                      fila['tipo'] == 'rechazo'
                                                  ? '${fila['cantidad']}'
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              '${fila['saldo']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    fila['saldo'] > 0
                                                        ? Colors.green
                                                        : (fila['saldo'] < 0
                                                            ? Colors.red
                                                            : Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          PopupMenuButton(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 18,
                                            ),
                                            itemBuilder:
                                                (context) => [
                                                  PopupMenuItem(
                                                    child: const Row(
                                                      children: [
                                                        Icon(
                                                          Icons.edit,
                                                          size: 18,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Editar cantidad'),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      Future.delayed(
                                                        Duration.zero,
                                                        () => _editarCantidad(
                                                          fila['id'],
                                                          fila['cantidad'],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  PopupMenuItem(
                                                    child: const Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete,
                                                          size: 18,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Eliminar',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    onTap: () {
                                                      Future.delayed(
                                                        Duration.zero,
                                                        () =>
                                                            _confirmarEliminarMovimiento(
                                                              fila['id'],
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                          ),
                                        ),
                                      ],
                                    );
                                  });
                                }(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, int valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
