import 'package:basefundi/desktop/ventas/factura_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VentasTotalesDeskScreen extends StatefulWidget {
  const VentasTotalesDeskScreen({super.key});

  @override
  State<VentasTotalesDeskScreen> createState() =>
      _VentasTotalesDeskScreenState();
}

class _VentasTotalesDeskScreenState extends State<VentasTotalesDeskScreen> {
  String _searchCliente = '';
  DateTime? _selectedDate;

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
                      'Ventas  Totales',
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
                            stream:
                                FirebaseFirestore.instance
                                    .collection('ventas')
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
                                  child: Text('No hay ventas registradas.'),
                                );
                              }

                              final allVentas = snapshot.data!.docs;

                              final filteredByCliente =
                                  allVentas.where((venta) {
                                    final cliente =
                                        (venta['cliente'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                    return cliente.contains(
                                      _searchCliente.toLowerCase(),
                                    );
                                  }).toList();

                              final filteredVentas =
                                  _selectedDate != null
                                      ? filteredByCliente.where((venta) {
                                        final fecha = venta['fecha']?.toDate();
                                        return fecha != null &&
                                            fecha.year == _selectedDate!.year &&
                                            fecha.month ==
                                                _selectedDate!.month &&
                                            fecha.day == _selectedDate!.day;
                                      }).toList()
                                      : filteredByCliente;

                              if (filteredVentas.isEmpty) {
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
                                itemCount: filteredVentas.length,
                                itemBuilder: (context, index) {
                                  final venta = filteredVentas[index];
                                  final cliente =
                                      venta['cliente'] ?? 'Desconocido';
                                  final codigoComprobante =
                                      venta['codigo_comprobante'] ??
                                      'Sin código';
                                  final fecha = venta['fecha']?.toDate();
                                  final total = venta['total'] ?? 0;

                                  return GestureDetector(
                                    onTap: () {
                                      navigateWithTransition(
                                        context: context,
                                        destination: FacturaDetalleDeskScreen(
                                          venta: venta,
                                        ),
                                        transition: TransitionType.fade,
                                        replace: false,
                                      );
                                    },

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
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.receipt_long,
                                                color: Color(0xFF2C3E50),
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
                                                  Text(
                                                    '$codigoComprobante',
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    fecha != null
                                                        ? '${fecha.day}/${fecha.month}/${fecha.year} — ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
                                                        : 'Sin fecha',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '\$${(total as num).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2C3E50),
                                              ),
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
                ? 'Filtrar por fecha'
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
