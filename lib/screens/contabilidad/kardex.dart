import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KardexScreen extends StatefulWidget {
  const KardexScreen({super.key});

  @override
  State<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends State<KardexScreen> {
  String _codigoProducto = '';

  Future<List<Map<String, dynamic>>> obtenerMovimientosKardex(
    String codigo,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // ✅ 1. Entradas
    final entradasSnap =
        await firestore
            .collection('historial_inventario_general')
            .where('codigo', isEqualTo: codigo)
            .get();

    final entradas = entradasSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'tipo': 'entrada',
        'cantidad': (data['cantidad'] ?? 0).toDouble(),
        'precio_unitario': (data['costo_unitario'] ?? 0).toDouble(),
        'fecha': (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    });

    // ✅ 2. Salidas (ventas)
    final ventasSnap = await firestore.collection('ventas').get();
    final salidas = ventasSnap.docs.expand((doc) {
      final data = doc.data();
      final fecha = (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
      final productos = (data['productos'] as List<dynamic>).where(
        (p) => p['codigo'] == codigo,
      );

      return productos.map((p) {
        return {
          'tipo': 'salida',
          'cantidad': (p['cantidad'] ?? 0).toDouble(),
          'precio_unitario': (p['precio'] ?? 0).toDouble(),
          'fecha': fecha,
        };
      });
    });

    // ✅ 3. Unir y ordenar
    final movimientos = [...entradas, ...salidas].toList();
    movimientos.sort((a, b) => a['fecha'].compareTo(b['fecha']));

    return movimientos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: const Center(
                child: Text(
                  'Kardex de Producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Buscador
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Código de producto...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _codigoProducto = value.trim();
                  });
                },
              ),
            ),

            // Tabla Kardex
            Expanded(
              child:
                  _codigoProducto.isEmpty
                      ? const Center(
                        child: Text('Ingresa un código de producto'),
                      )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                        future: obtenerMovimientosKardex(_codigoProducto),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final movimientos = snapshot.data!;

                          if (movimientos.isEmpty) {
                            return const Center(
                              child: Text('No hay movimientos.'),
                            );
                          }

                          double stockAcumulado = 0;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Fecha')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Entrada')),
                                DataColumn(label: Text('Salida')),
                                DataColumn(label: Text('Stock')),
                                DataColumn(label: Text('P.Unitario')),
                                DataColumn(label: Text('Total')),
                              ],
                              rows:
                                  movimientos.map((mov) {
                                    final tipo = mov['tipo'] ?? '';
                                    final cantidad = mov['cantidad'] ?? 0.0;
                                    final precioUnitario =
                                        mov['precio_unitario'] ?? 0.0;
                                    final fecha = mov['fecha'] as DateTime;

                                    if (tipo == 'entrada') {
                                      stockAcumulado += cantidad;
                                    } else if (tipo == 'salida') {
                                      stockAcumulado -= cantidad;
                                    }

                                    final total = cantidad * precioUnitario;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(fecha),
                                          ),
                                        ),
                                        DataCell(Text(tipo.toUpperCase())),
                                        DataCell(
                                          Text(
                                            tipo == 'entrada'
                                                ? '$cantidad'
                                                : '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            tipo == 'salida'
                                                ? '$cantidad'
                                                : '-',
                                          ),
                                        ),
                                        DataCell(Text('$stockAcumulado')),
                                        DataCell(
                                          Text(
                                            '\$${precioUnitario.toStringAsFixed(2)}',
                                          ),
                                        ),
                                        DataCell(
                                          Text('\$${total.toStringAsFixed(2)}'),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
