import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  String _filtroCliente = '';

  Future<void> _generarPdf(List<Map<String, dynamic>> ventas) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy – HH:mm');

    for (var venta in ventas) {
      pdf.addPage(
        pw.Page(
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '🧾 Detalle de Venta',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Cliente: ${venta['cliente']}'),
                  pw.Text(
                    'Fecha: ${venta['fecha'] != null ? dateFormat.format(venta['fecha']) : 'Sin fecha'}',
                  ),
                  pw.Text('Método de Pago: ${venta['metodoPago']}'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Productos:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Table.fromTextArray(
                    headers: ['Cod', 'Nombre', 'Cant', 'Precio', 'Total'],
                    data:
                        (venta['productos'] as List).map<List<String>>((p) {
                          final producto = p as Map<String, dynamic>;
                          return [
                            producto['codigo'] ?? '',
                            producto['nombre'] ?? '',
                            producto['cantidad'].toString(),
                            '\$${(producto['precio'] ?? 0).toStringAsFixed(2)}',
                            '\$${(producto['subtotal'] ?? 0).toStringAsFixed(2)}',
                          ];
                        }).toList(),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Total: \$${(venta['productos'] as List).fold<double>(0, (sum, item) {
                      final p = item as Map<String, dynamic>;
                      return sum + (p['subtotal'] ?? 0);
                    }).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reporte de Ventas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    tooltip: 'Exportar todo a PDF',
                    onPressed: () async {
                      final snapshot =
                          await FirebaseFirestore.instance
                              .collection('ventas')
                              .get();

                      final ventas =
                          snapshot.docs
                              .map((doc) {
                                final data = doc.data();
                                return {
                                  'cliente': data['cliente'] ?? 'Desconocido',
                                  'fecha': data['fecha']?.toDate(),
                                  'metodoPago': data['metodoPago'] ?? '---',
                                  'productos': data['productos'] ?? [],
                                };
                              })
                              .where((v) {
                                return v['cliente']
                                    .toString()
                                    .toLowerCase()
                                    .contains(_filtroCliente.toLowerCase());
                              })
                              .toList();

                      _generarPdf(ventas);
                    },
                  ),
                ],
              ),
            ),

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filtroCliente = value;
                  });
                },
              ),
            ),

            // Lista de Ventas con StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('ventas')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ventas =
                      snapshot.data!.docs
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return {
                              'cliente': data['cliente'] ?? 'Desconocido',
                              'fecha': data['fecha']?.toDate(),
                              'metodoPago': data['metodoPago'] ?? '---',
                              'productos': data['productos'] ?? [],
                            };
                          })
                          .where((v) {
                            return v['cliente']
                                .toString()
                                .toLowerCase()
                                .contains(_filtroCliente.toLowerCase());
                          })
                          .toList();

                  if (ventas.isEmpty) {
                    return const Center(
                      child: Text('No hay ventas que coincidan.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: ventas.length,
                    itemBuilder: (context, index) {
                      final venta = ventas[index];
                      final fecha =
                          venta['fecha'] != null
                              ? DateFormat(
                                'dd/MM/yyyy – HH:mm',
                              ).format(venta['fecha'])
                              : 'Sin fecha';
                      final total = (venta['productos'] as List).fold<double>(
                        0,
                        (sum, item) {
                          final producto = item as Map<String, dynamic>;
                          final subtotal = producto['subtotal'];
                          return sum +
                              (subtotal is num
                                  ? subtotal.toDouble()
                                  : double.tryParse(subtotal.toString()) ?? 0);
                        },
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venta['cliente'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Fecha: $fecha'),
                              Text('Método de Pago: ${venta['metodoPago']}'),
                              const SizedBox(height: 6),
                              Text(
                                'Total: \$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4682B4),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () => _generarPdf([venta]),
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Exportar PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4682B4),
                                    foregroundColor: Colors.white,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
