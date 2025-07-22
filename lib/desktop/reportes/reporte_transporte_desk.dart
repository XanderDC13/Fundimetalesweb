import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class ReporteTransporteDeskScreen extends StatefulWidget {
  const ReporteTransporteDeskScreen({super.key});

  @override
  State<ReporteTransporteDeskScreen> createState() =>
      _ReporteTransporteDeskScreenState();
}

class _ReporteTransporteDeskScreenState
    extends State<ReporteTransporteDeskScreen> {
  List<Map<String, dynamic>> _reporte = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    setState(() {
      _cargando = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('transporte')
        .orderBy('fecha_registro', descending: true);

    if (_fechaInicio != null) {
      query = query.where(
        'fecha_registro',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
      );
    }
    if (_fechaFin != null) {
      query = query.where(
        'fecha_registro',
        isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
      );
    }

    final snapshot = await query.get();

    List<Map<String, dynamic>> reporte = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fecha = (data['fecha_registro'] as Timestamp?)?.toDate();

      reporte.add({
        'codigo': data['codigo'],
        'nombre': data['nombre'],
        'fecha': fecha,
        'salida_sede': data['salida_sede'],
        'llegada_fabrica': data['llegada_fabrica'],
        'salida_fabrica': data['salida_fabrica'],
        'llegada_sede': data['llegada_sede'],
        'tiempo_sede_fabrica': data['tiempo_sede_fabrica'],
        'tiempo_fabrica_sede': data['tiempo_fabrica_sede'],
      });
    }

    setState(() {
      _reporte = reporte;
      _cargando = false;
    });
  }

  void _limpiarFiltro() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
    _obtenerDatos();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return DateFormat('dd/MM/yyyy hh:mm a').format(fecha);
  }

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

  Future<void> _generarPDF(
    List<Map<String, dynamic>> data, {
    bool unoSolo = false,
  }) async {
    final pdf = pw.Document();

    final lista =
        data.map((item) {
          return [
            _formatearFecha(item['fecha']),
            (item['salida_sede'] ?? '—').toString(),
            (item['llegada_fabrica'] ?? '—').toString(),
            (item['salida_fabrica'] ?? '—').toString(),
            (item['llegada_sede'] ?? '—').toString(),
            (item['tiempo_sede_fabrica'] ?? '—').toString(),
            (item['tiempo_fabrica_sede'] ?? '—').toString(),
          ];
        }).toList();

    pdf.addPage(
      buildReportePDF(
        titulo: 'Reporte de Transporte',
        headers: [
          'Fecha Registro',
          'Salida Sede',
          'Llegada Fábrica',
          'Salida Fábrica',
          'Llegada Sede',
          'Demora S→F',
          'Demora F→S',
        ],
        dataRows: lista,
        footerText: unoSolo ? null : 'Total registros: ${lista.length}',
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
      _obtenerDatos();
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
      _obtenerDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // CABECERA
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
                      'Reporte de Transporte',
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

          // CONTENIDO principal
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // FILTROS FECHA
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _seleccionarFechaInicio,
                          icon: const Icon(
                            Icons.date_range,
                            color: Colors.white,
                          ),
                          label: Text(
                            _fechaInicio == null
                                ? 'Desde'
                                : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_fechaInicio!),
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _seleccionarFechaFin,
                          icon: const Icon(
                            Icons.date_range,
                            color: Colors.white,
                          ),
                          label: Text(
                            _fechaFin == null
                                ? 'Hasta'
                                : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _limpiarFiltro,
                        icon: const Icon(Icons.clear, color: Color(0xFF4682B4)),
                        tooltip: 'Limpiar filtro',
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () => _generarPDF(_reporte),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // LISTA DE REGISTROS
                  _cargando
                      ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : _reporte.isEmpty
                      ? const Expanded(
                        child: Center(
                          child: Text(
                            'No hay registros para mostrar.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      )
                      : Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _reporte.length,
                          itemBuilder: (context, index) {
                            final item = _reporte[index];
                            return Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📅 Fecha: ${_formatearFecha(item['fecha'])}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Table(
                                        border: TableBorder.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        defaultVerticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                            ),
                                            children: const [
                                              _TablaHeader('Salida Sede'),
                                              _TablaHeader('Llegada Fábrica'),
                                              _TablaHeader('Salida Fábrica'),
                                              _TablaHeader('Llegada Sede'),
                                              _TablaHeader('Demora S→F'),
                                              _TablaHeader('Demora F→S'),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              _TablaCell(item['salida_sede']),
                                              _TablaCell(
                                                item['llegada_fabrica'],
                                              ),
                                              _TablaCell(
                                                item['salida_fabrica'],
                                              ),
                                              _TablaCell(item['llegada_sede']),
                                              _TablaCell(
                                                item['tiempo_sede_fabrica'],
                                              ),
                                              _TablaCell(
                                                item['tiempo_fabrica_sede'],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => _generarPDF([
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
          ),
        ],
      ),
    );
  }
}

class _TablaHeader extends StatelessWidget {
  final String text;
  const _TablaHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TablaCell extends StatelessWidget {
  final String? text;
  const _TablaCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text ?? '—',
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}
