import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReporteInventarioScreen extends StatefulWidget {
  const ReporteInventarioScreen({super.key});

  @override
  _ReporteInventarioScreenState createState() =>
      _ReporteInventarioScreenState();
}

class _ReporteInventarioScreenState extends State<ReporteInventarioScreen> {
  final Map<String, Map<String, dynamic>> _datosFundicion = {};
  final Map<String, Map<String, dynamic>> _datosPintura = {};
  List<Map<String, dynamic>> _reporte = [];
  String _filtroNombre = '';

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    final fundicionSnapshot =
        await FirebaseFirestore.instance
            .collection('inventario_fundicion')
            .get();
    final pinturaSnapshot =
        await FirebaseFirestore.instance.collection('inventario_pintura').get();

    for (var doc in fundicionSnapshot.docs) {
      final data = doc.data();
      final codigo = data['codigo'];
      final nombre = data['nombre'] ?? 'Desconocido';
      final cantidad = data['cantidad'] ?? 0;

      if (_datosFundicion.containsKey(codigo)) {
        _datosFundicion[codigo]!['cantidad'] += cantidad;
      } else {
        _datosFundicion[codigo] = {
          'codigo': codigo,
          'nombre': nombre,
          'cantidad': cantidad,
        };
      }
    }

    for (var doc in pinturaSnapshot.docs) {
      final data = doc.data();
      final codigo = data['codigo'];
      final nombre = data['nombre'] ?? 'Desconocido';
      final cantidad = data['cantidad'] ?? 0;

      if (_datosPintura.containsKey(codigo)) {
        _datosPintura[codigo]!['cantidad'] += cantidad;
      } else {
        _datosPintura[codigo] = {
          'codigo': codigo,
          'nombre': nombre,
          'cantidad': cantidad,
        };
      }
    }

    _generarReporte();
  }

  void _generarReporte() {
    final codigos = {..._datosFundicion.keys, ..._datosPintura.keys};
    List<Map<String, dynamic>> reporte = [];

    for (var codigo in codigos) {
      final fundicion = _datosFundicion[codigo];
      final pintura = _datosPintura[codigo];

      final nombre =
          fundicion?['nombre'] ?? pintura?['nombre'] ?? 'Desconocido';
      final cantidadFundicion = fundicion?['cantidad'] ?? 0;
      final cantidadPintura = pintura?['cantidad'] ?? 0;
      final danados = cantidadFundicion - cantidadPintura;
      final promedioDanado =
          cantidadFundicion > 0 ? (danados / cantidadFundicion) * 100 : 0;
      final total = cantidadFundicion + cantidadPintura;

      reporte.add({
        'codigo': codigo,
        'nombre': nombre,
        'fundicion': cantidadFundicion,
        'pintura': cantidadPintura,
        'danados': danados,
        'promedioDanado': promedioDanado,
        'totalAcumulado': total,
      });
    }

    setState(() {
      _reporte = reporte;
    });
  }

  // 👉 PLANTILLA PDF REUTILIZABLE
  pw.MultiPage buildReportePDF({
    required String titulo,
    required List<String> headers,
    required List<List<String>> dataRows,
    String? footerText,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build:
          (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              border: null,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
              headers: headers,
              data: dataRows,
            ),
            pw.SizedBox(height: 20),
            if (footerText != null)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  footerText,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
          ],
    );
  }

  Future<void> _generarPdf(
    List<Map<String, dynamic>> datos, {
    bool unoSolo = false,
  }) async {
    final pdf = pw.Document();

    final dataRows =
        datos.map((item) {
          return [
            item['codigo'].toString(),
            item['nombre'].toString(),
            item['fundicion'].toString(),
            item['pintura'].toString(),
            item['danados'].toString(),
            '${item['promedioDanado'].toStringAsFixed(2)}%',
            item['totalAcumulado'].toString(),
          ];
        }).toList();

    pdf.addPage(
      buildReportePDF(
        titulo: 'Reporte de Inventario',
        headers: [
          'Código',
          'Nombre',
          'Fundición',
          'Pintura',
          'Dañados',
          '% Dañado',
          'Total',
        ],
        dataRows: dataRows,
        footerText: unoSolo ? null : 'Total productos: ${dataRows.length}',
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Widget _buildInfoText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Text(value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reporteFiltrado =
        _reporte.where((item) {
          return item['nombre'].toString().toLowerCase().contains(
            _filtroNombre.toLowerCase(),
          );
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ AppBar
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
                    'Reporte de Inventario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    tooltip: 'Descargar PDF',
                    onPressed: () => _generarPdf(reporteFiltrado),
                  ),
                ],
              ),
            ),

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
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
                    _filtroNombre = value;
                  });
                },
              ),
            ),

            // Lista de Reporte
            Expanded(
              child:
                  reporteFiltrado.isEmpty
                      ? const Center(
                        child: Text('No hay productos que coincidan.'),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: reporteFiltrado.length,
                        itemBuilder: (context, index) {
                          final item = reporteFiltrado[index];
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
                                    '${item['codigo']} - ${item['nombre']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoText(
                                        'Fundición',
                                        item['fundicion'].toString(),
                                      ),
                                      _buildInfoText(
                                        'Pintura',
                                        item['pintura'].toString(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoText(
                                        'Dañados',
                                        item['danados'].toString(),
                                      ),
                                      _buildInfoText(
                                        '% Dañado',
                                        '${item['promedioDanado'].toStringAsFixed(2)}%',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _buildInfoText(
                                    'Total Acumulado',
                                    item['totalAcumulado'].toString(),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () => _generarPdf([
                                            item,
                                          ], unoSolo: true),
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Exportar PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4682B4,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
