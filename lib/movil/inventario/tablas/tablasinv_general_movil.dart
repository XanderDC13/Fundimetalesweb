import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TablainvScreen extends StatefulWidget {
  final String referencia;
  final String nombre;

  const TablainvScreen({
    super.key,
    required this.referencia,
    required this.nombre,
  });

  @override
  State<TablainvScreen> createState() => _TablainvScreenState();
}

class _TablainvScreenState extends State<TablainvScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Column(
        children: [
          SafeArea(
            child: Container(
              width: double.infinity,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
          ElevatedButton.icon(
            onPressed: () => _seleccionarFecha(context),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _fechaSeleccionada != null
                  ? 'Filtrado: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}'
                  : 'Filtrar por fecha',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4682B4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
        .collection('historial_inventario_general')
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
          .where('fecha_actualizacion', isGreaterThanOrEqualTo: inicioDelDia)
          .where('fecha_actualizacion', isLessThanOrEqualTo: finDelDia);
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          query.orderBy('fecha_actualizacion', descending: true).snapshots(),
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
            final double totalWidth = constraints.maxWidth;
            final double anchoFecha = totalWidth * 0.50;
            final double anchoCantidad = totalWidth * 0.50;

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF4682B4),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                columnSpacing: 0,
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 150, // Dale ancho real a la cabecera
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Fecha',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 150, // Dale ancho real a la cabecera
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Cantidad',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                rows:
                    docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      final cantidad = data?['cantidad'] ?? 0;
                      final fecha =
                          (data?['fecha_actualizacion'] as Timestamp?)
                              ?.toDate();
                      final fechaStr =
                          fecha != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
                              : 'Sin fecha';

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: anchoFecha,
                              child: Align(
                                alignment:
                                    Alignment
                                        .centerLeft, // Mueve a la izquierda
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                  ), // Empuja aún más
                                  child: Text(
                                    fechaStr,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: anchoCantidad,
                              child: Align(
                                alignment:
                                    Alignment.centerRight, // Mueve a la derecha
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 140,
                                  ), // Empuja aún más
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
            );
          },
        );
      },
    );
  }
}
