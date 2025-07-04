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

class _ReporteInventarioScreenState extends State<ReporteInventarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroNombre = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  pw.MultiPage buildReporteInventarioPDF({
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

  Stream<List<Map<String, dynamic>>> _getEntradas(String coleccion) {
    final ordenCampo =
        coleccion == 'historial_inventario_general'
            ? 'fecha_actualizacion'
            : 'fecha';

    return FirebaseFirestore.instance
        .collection(coleccion)
        .orderBy('codigo')
        .orderBy(ordenCampo, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => doc.data())
                  .where(
                    (e) => (e['nombre'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_filtroNombre.toLowerCase()),
                  )
                  .toList(),
        );
  }

  Widget _buildTabla(String coleccion) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getEntradas(coleccion),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entradas = snapshot.data!;
        if (entradas.isEmpty) {
          return const Center(child: Text('No hay registros.'));
        }

        return SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.blue.shade100,
            ),
            columnSpacing: 0,
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Cant')),
            ],
            rows:
                entradas.map((entrada) {
                  final fechaCampo =
                      coleccion == 'historial_inventario_general'
                          ? entrada['fecha_actualizacion']
                          : entrada['fecha'];
                  final fecha =
                      fechaCampo != null
                          ? (fechaCampo as Timestamp).toDate()
                          : null;

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 55,
                          child: Text(
                            fecha != null
                                ? fecha.toLocal().toString().split(' ')[0]
                                : '-',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 71,
                          child: Text(
                            '${entrada['codigo'] ?? '-'}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              '${entrada['nombre'] ?? '-'}',
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 18,
                          child: Text(
                            '${entrada['cantidad'] ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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
  }

  Future<void> _exportarPDF(String coleccion) async {
    final pdf = pw.Document();

    final snapshot =
        await FirebaseFirestore.instance
            .collection(coleccion)
            .orderBy('codigo')
            .orderBy(
              coleccion == 'historial_inventario_general'
                  ? 'fecha_actualizacion'
                  : 'fecha',
              descending: true,
            )
            .get();

    final entradas = snapshot.docs.map((doc) => doc.data()).toList();

    final lista =
        entradas.map((entrada) {
          final fechaCampo =
              coleccion == 'historial_inventario_general'
                  ? entrada['fecha_actualizacion']
                  : entrada['fecha'];
          final fecha =
              fechaCampo != null
                  ? (fechaCampo as Timestamp)
                      .toDate()
                      .toLocal()
                      .toString()
                      .split(' ')[0]
                  : '-';

          return [
            fecha,
            '${entrada['codigo'] ?? '-'}',
            '${entrada['nombre'] ?? '-'}',
            '${entrada['cantidad'] ?? 0}',
          ];
        }).toList();

    pdf.addPage(
      buildReporteInventarioPDF(
        titulo: 'Reporte de ${coleccion.replaceAll('_', ' ').toUpperCase()}',
        headers: ['Fecha', 'Código', 'Nombre', 'Cant'],
        dataRows: lista,
        footerText: 'Total registros: ${lista.length}',
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final colecciones = [
      'inventario_fundicion',
      'inventario_pintura',
      'historial_inventario_general',
    ];

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
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: const Text(
                'Reporte de Inventario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Tab(text: 'Fundición'),
                    Tab(text: 'Pintura'),
                    Tab(text: 'General'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabla('inventario_fundicion'),
                  _buildTabla('inventario_pintura'),
                  _buildTabla('historial_inventario_general'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  final coleccion = colecciones[_tabController.index];
                  _exportarPDF(coleccion);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar a PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
