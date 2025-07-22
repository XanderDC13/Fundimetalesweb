import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TablaInvFundicionDeskScreen extends StatefulWidget {
  final String referencia;
  final String nombre;

  const TablaInvFundicionDeskScreen({
    super.key,
    required this.referencia,
    required this.nombre,
  });

  @override
  State<TablaInvFundicionDeskScreen> createState() =>
      _TablaInvFundicionDeskScreenState();
}

class _TablaInvFundicionDeskScreenState
    extends State<TablaInvFundicionDeskScreen> {
  DateTime? _fechaSeleccionada;

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Historial - ${widget.nombre}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildFiltroFecha(context),
          const SizedBox(height: 12),
          Expanded(child: _buildTabla(widget.referencia)),
        ],
      ),
    );
  }

  Widget _buildFiltroFecha(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _seleccionarFecha(context),
              icon: const Icon(Icons.calendar_today, size: 20),
              label: Text(
                _fechaSeleccionada != null
                    ? 'Filtrado: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}'
                    : 'Filtrar por fecha',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                minimumSize: const Size(140, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (_fechaSeleccionada != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _fechaSeleccionada = null;
                });
              },
              child: const Text(
                'Limpiar filtro de fecha',
                style: TextStyle(color: Color(0xFF4682B4)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabla(String referencia) {
    Query query = FirebaseFirestore.instance
        .collection('inventario_fundicion')
        .where('referencia', isEqualTo: referencia);

    if (_fechaSeleccionada != null) {
      final inicioDelDia = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        0,
        0,
        0,
      );
      final finDelDia = inicioDelDia.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );

      query = query
          .where('fecha', isGreaterThanOrEqualTo: inicioDelDia)
          .where('fecha', isLessThanOrEqualTo: finDelDia);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('fecha', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No hay registros para esta fecha.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final anchoFecha = 150.0;
            final anchoProducto = totalWidth - anchoFecha - 150;
            final anchoCantidad = 150.0;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFF4682B4),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  columnSpacing: 0,
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: anchoFecha,
                        child: Center(child: Text('Fecha')),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: anchoProducto,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            'Producto',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: anchoCantidad,
                        child: Center(child: Text('Cantidad')),
                      ),
                    ),
                  ],
                  rows:
                      docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nombre = data['nombre'] ?? 'Sin nombre';
                        final cantidad = data['cantidad'] ?? 0;
                        final fecha = (data['fecha'] as Timestamp?)?.toDate();
                        final fechaStr =
                            fecha != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
                                : 'Sin fecha';

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: anchoFecha,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Text(
                                    fechaStr,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: anchoProducto,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Text(
                                    nombre,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: anchoCantidad,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      cantidad.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
