import 'package:basefundi/screens/ventas/factura.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VentasTotalesScreen extends StatefulWidget {
  const VentasTotalesScreen({super.key});

  @override
  State<VentasTotalesScreen> createState() => _VentasTotalesScreenState();
}

class _VentasTotalesScreenState extends State<VentasTotalesScreen> {
  String _searchCliente = '';
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No hay ventas registradas.'),
                    );
                  }

                  final allVentas = snapshot.data!.docs;

                  // Filtro por cliente
                  final filteredByCliente =
                      allVentas.where((venta) {
                        final cliente =
                            (venta['cliente'] ?? '').toString().toLowerCase();
                        return cliente.contains(_searchCliente.toLowerCase());
                      }).toList();

                  // Filtro por fecha (si se seleccionó)
                  final filteredVentas =
                      _selectedDate != null
                          ? filteredByCliente.where((venta) {
                            final fecha = venta['fecha']?.toDate();
                            return fecha != null &&
                                fecha.year == _selectedDate!.year &&
                                fecha.month == _selectedDate!.month &&
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredVentas.length,
                    itemBuilder: (context, index) {
                      final venta = filteredVentas[index];
                      final cliente = venta['cliente'] ?? 'Desconocido';
                      final fecha = venta['fecha']?.toDate();
                      final total = venta['total'] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => FacturaDetalleScreen(venta: venta),
                            ),
                          );
                        },
                        child: Card(
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
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(12),
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Center(
        child: Text(
          'Ventas Totales',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
