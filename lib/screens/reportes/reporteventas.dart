import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen>
    with SingleTickerProviderStateMixin {
  String _filtroCliente = '';
  late final TabController _tabController;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _disposed = true;
    _tabController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      setState(fn);
    }
  }

  Future<void> _generarPdf(List<Map<String, dynamic>> ventas) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

      // Carga logo desde assets
      final Uint8List logoBytes = await rootBundle
          .load('lib/assets/logo.png')
          .then((value) => value.buffer.asUint8List());
      final logoImage = pw.MemoryImage(logoBytes);

      for (var venta in ventas) {
        final productos = (venta['productos'] ?? []) as List;

        double subtotal = 0;
        for (var item in productos) {
          final p = item as Map<String, dynamic>;
          final sub = p['subtotal'];
          final valor =
              sub is num
                  ? sub.toDouble()
                  : double.tryParse(sub.toString()) ?? 0;
          subtotal += valor;
        }

        final tipoComprobanteRaw = venta['tipoComprobante'];
        final tipoComprobante =
            (tipoComprobanteRaw == null ||
                    tipoComprobanteRaw == '' ||
                    tipoComprobanteRaw == '---')
                ? 'Nota de Venta'
                : tipoComprobanteRaw;

        final total =
            tipoComprobante.toLowerCase() == 'factura'
                ? subtotal * 1.15
                : subtotal;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build:
                (context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              tipoComprobante,
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF4682B4),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text('Cliente: ${venta['cliente'] ?? '---'}'),
                            pw.Text(
                              'Fecha: ${venta['fecha'] != null ? dateFormat.format(venta['fecha']) : 'Sin fecha'}',
                            ),
                            pw.Text(
                              'Método de Pago: ${venta['metodoPago'] ?? '---'}',
                            ),
                            pw.Text('Tipo Comprobante: $tipoComprobante'),
                          ],
                        ),
                        pw.Container(
                          height: 60,
                          width: 60,
                          child: pw.Image(logoImage),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Table.fromTextArray(
                      headerDecoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF4682B4),
                      ),
                      headerStyle: pw.TextStyle(
                        color: PdfColor.fromInt(0xFFFFFFFF),
                        fontWeight: pw.FontWeight.bold,
                      ),
                      border: pw.TableBorder.all(
                        color: PdfColor.fromInt(0xFF4682B4),
                      ),
                      headers: ['Ref', 'Nombre', 'Cant', 'Precio', 'Subtotal'],
                      data:
                          productos.map<List<String>>((p) {
                            final producto = p as Map<String, dynamic>;
                            return [
                              producto['referencia'] ?? '',
                              producto['nombre'] ?? '',
                              producto['cantidad'].toString(),
                              '\$${(producto['precio'] ?? 0).toStringAsFixed(2)}',
                              '\$${(producto['subtotal'] ?? 0).toStringAsFixed(2)}',
                            ];
                          }).toList(),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromInt(0xFF4682B4),
                          ),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          'TOTAL: \$${total.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColor.fromInt(0xFF4682B4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        );
      }

      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
    }
  }

  Widget _buildListaVentas(bool esFactura) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ventas')
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final ventas =
            snapshot.data!.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'cliente': data['cliente'] ?? 'Desconocido',
                    'fecha': data['fecha']?.toDate(),
                    'metodoPago': data['metodoPago'] ?? '---',
                    'tipoComprobante': data['tipoComprobante'] ?? '---',
                    'productos': data['productos'] ?? [],
                  };
                })
                .where((v) {
                  final esFacturaReal =
                      (v['tipoComprobante'] ?? '').toString().toLowerCase() ==
                      'factura';
                  final esNotaVenta = !esFacturaReal;
                  return (esFactura ? esFacturaReal : esNotaVenta) &&
                      v['cliente'].toString().toLowerCase().contains(
                        _filtroCliente.toLowerCase(),
                      );
                })
                .toList();

        if (ventas.isEmpty) {
          return const Center(child: Text('No hay ventas que coincidan.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: ventas.length,
          itemBuilder: (context, index) {
            final venta = ventas[index];
            final fecha =
                venta['fecha'] != null
                    ? DateFormat('dd/MM/yyyy – HH:mm').format(venta['fecha'])
                    : 'Sin fecha';
            final tipoComprobante = venta['tipoComprobante'] ?? '---';

            final subtotal = (venta['productos'] as List).fold<double>(0, (
              sum,
              item,
            ) {
              final producto = item as Map<String, dynamic>;
              final precio = producto['precio'] ?? 0;
              final cantidad = producto['cantidad'] ?? 0;
              final sub =
                  (precio is num
                      ? precio.toDouble()
                      : double.tryParse(precio.toString()) ?? 0) *
                  (cantidad is num
                      ? cantidad.toDouble()
                      : double.tryParse(cantidad.toString()) ?? 0);
              return sum + sub;
            });

            final total =
                tipoComprobante.toLowerCase() == 'factura'
                    ? subtotal * 1.15
                    : subtotal;

            return Card(
              color: Colors.white,
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
                    Text(
                      'Comprobante: $tipoComprobante',
                      style: TextStyle(
                        color:
                            tipoComprobante.toLowerCase() == 'factura'
                                ? Colors.green
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
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
              child: const Text(
                'Reporte de Ventas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                  _safeSetState(() {
                    _filtroCliente = value;
                  });
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF4682B4),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF4682B4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF4682B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Facturas'),
                    Tab(text: 'Notas de Venta'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildListaVentas(true), _buildListaVentas(false)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
