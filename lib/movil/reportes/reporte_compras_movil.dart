import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReporteComprasMobileScreen extends StatefulWidget {
  const ReporteComprasMobileScreen({super.key});

  @override
  State<ReporteComprasMobileScreen> createState() =>
      _ReporteComprasMobileScreenState();
}

class _ReporteComprasMobileScreenState
    extends State<ReporteComprasMobileScreen> {
  List<Map<String, dynamic>> _reporte = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = false;
  double _totalGeneral = 0.0;
  double _promedioMensual = 0.0;

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
        .collection('proformasfundicion')
        .orderBy('fecha', descending: true);

    if (_fechaInicio != null) {
      query = query.where(
        'fecha',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
      );
    }
    if (_fechaFin != null) {
      query = query.where(
        'fecha',
        isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
      );
    }

    final snapshot = await query.get();

    List<Map<String, dynamic>> reporte = [];
    double totalGeneral = 0.0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      final items = data['items'] as List<dynamic>? ?? [];

      // Calcular total de la proforma
      double totalProforma = 0.0;
      for (var item in items) {
        final itemMap = item as Map<String, dynamic>;
        final total =
            double.tryParse(itemMap['total']?.toString() ?? '0') ?? 0.0;
        totalProforma += total;
      }

      totalGeneral += totalProforma;

      reporte.add({
        'numero': data['numero'] ?? '—',
        'cliente': data['cliente'] ?? '—',
        'fecha': fecha,
        'items': items,
        'totalProforma': totalProforma,
      });
    }

    // Calcular promedio mensual
    double promedioMensual = 0.0;
    if (reporte.isNotEmpty) {
      // Agrupar por mes y año
      Map<String, double> totalesPorMes = {};

      for (var item in reporte) {
        final fecha = item['fecha'] as DateTime?;
        if (fecha != null) {
          final mesAno = DateFormat('yyyy-MM').format(fecha);
          totalesPorMes[mesAno] =
              (totalesPorMes[mesAno] ?? 0) + item['totalProforma'];
        }
      }

      if (totalesPorMes.isNotEmpty) {
        final sumaTotal = totalesPorMes.values.reduce((a, b) => a + b);
        promedioMensual = sumaTotal / totalesPorMes.length;
      }
    }

    setState(() {
      _reporte = reporte;
      _totalGeneral = totalGeneral;
      _promedioMensual = promedioMensual;
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
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String _formatearMoneda(double valor) {
    return '\$${valor.toStringAsFixed(2)}';
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildReportePDFHeader(unoSolo),
                    pw.SizedBox(height: 15),
                    _buildReportePDFDateRange(),
                    pw.SizedBox(height: 15),
                    _buildReportePDFTable(data),
                    pw.SizedBox(height: 15),
                    _buildReportePDFTotales(data, unoSolo),
                    pw.SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildReportePDFHeader(bool unoSolo) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(10),
            color: PdfColor.fromHex('#4682B4'),
            child: pw.Text(
              unoSolo
                  ? 'COPIA DE COMPRA DE MATERIA PRIMA'
                  : 'REPORTE DE COMPRAS DE MATERIA PRIMA',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(8),
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Column(
              children: [
                pw.Text(
                  'FUNDIMETALES DEL NORTE',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  unoSolo ? 'DETALLE DE COMPRA' : 'REPORTE CONSOLIDADO',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Dirección: Av Brasil y Panamá - (Tulcán Ecuador) - telf: 2962017',
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportePDFDateRange() {
    String rangoFechas = '';
    if (_fechaInicio != null && _fechaFin != null) {
      rangoFechas =
          'Período: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}';
    } else if (_fechaInicio != null) {
      rangoFechas = 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}';
    } else if (_fechaFin != null) {
      rangoFechas = 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}';
    } else {
      rangoFechas = 'Período: Todos los registros';
    }

    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL REPORTE',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(rangoFechas, style: pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 2),
          pw.Text(
            'Total de registros: ${_reporte.length}',
            style: pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportePDFTable(List<Map<String, dynamic>> data) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.all(6),
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'NÚMERO',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'CLIENTE',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'FECHA',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'ITEMS',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Filas de datos
          ...data.map((item) {
            final items = item['items'] as List<dynamic>;
            String itemsTexto = items
                .map((i) {
                  final itemMap = i as Map<String, dynamic>;
                  return '${itemMap['descripcion']} (${itemMap['kilos']}kg)';
                })
                .join(', ');

            // Limitar el texto de items si es muy largo
            if (itemsTexto.length > 80) {
              itemsTexto = '${itemsTexto.substring(0, 80)}...';
            }

            return pw.Container(
              padding: pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item['numero']?.toString() ?? '—',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      (item['cliente']?.toString() ?? '—').toUpperCase(),
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item['fecha'] != null
                          ? DateFormat('dd/MM/yyyy').format(item['fecha'])
                          : '—',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      itemsTexto,
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${(item['totalProforma'] ?? 0.0).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildReportePDFTotales(
    List<Map<String, dynamic>> data,
    bool unoSolo,
  ) {
    double totalReporte = data.fold(
      0.0,
      (sum, item) => sum + (item['totalProforma'] ?? 0.0),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          padding: pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              if (!unoSolo) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Registros:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                    pw.Text(
                      '${data.length}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Promedio Mensual:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                    pw.Text(
                      '\$${_promedioMensual.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 4),
                color: PdfColor.fromHex('#fff3cd'),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      unoSolo ? 'TOTAL:' : 'TOTAL GENERAL:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '\$${totalReporte.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Container(
                width: 180,
                child: pw.Divider(thickness: 0.8, color: PdfColors.black),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Firma Autorizada',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reporte de Compras',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    onPressed: () => _generarPDF(_reporte),
                    tooltip: 'Descargar PDF',
                  ),
                ],
              ),
            ),

            // INDICADORES RESUMEN
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: const Color(0xFF4682B4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatearMoneda(_totalGeneral),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Card(
                      color: const Color(0xFF4682B4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Promedio',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatearMoneda(_promedioMensual),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Card(
                      color: const Color(0xFF4682B4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Proformas',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_reporte.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CONTENIDO PRINCIPAL
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // FILTROS DE FECHA
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _seleccionarFechaInicio,
                                icon: const Icon(
                                  Icons.date_range,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                label: Text(
                                  _fechaInicio == null
                                      ? 'Desde'
                                      : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_fechaInicio!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4682B4),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _seleccionarFechaFin,
                                icon: const Icon(
                                  Icons.date_range,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                label: Text(
                                  _fechaFin == null
                                      ? 'Hasta'
                                      : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_fechaFin!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4682B4),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: _limpiarFiltro,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB0BEC5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: const Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // TABLA DE REGISTROS
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
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Table(
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  top: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: const {
                                  0: FlexColumnWidth(2.2), // Fecha
                                  1: FlexColumnWidth(2.5), // Proforma
                                  2: FlexColumnWidth(2.8), // Cliente
                                  3: FlexColumnWidth(2.0), // Total
                                  4: FlexColumnWidth(1.5), // Acción
                                },
                                children: [
                                  // ENCABEZADO
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4682B4),
                                    ),
                                    children: const [
                                      _TablaHeaderMain('Fecha'),
                                      _TablaHeaderMain('Proforma'),
                                      _TablaHeaderMain('Cliente'),
                                      _TablaHeaderMain('Total'),
                                      _TablaHeaderMain('Acción'),
                                    ],
                                  ),
                                  // FILAS DE DATOS
                                  ..._reporte.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final isEven = index % 2 == 0;

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color:
                                            isEven
                                                ? Colors.grey.shade50
                                                : Colors.white,
                                      ),
                                      children: [
                                        _TablaCellMain(
                                          _formatearFecha(item['fecha']),
                                        ),
                                        _TablaCellMain(
                                          item['numero']?.toString() ?? '—',
                                        ),
                                        _TablaCellMain(
                                          item['cliente']?.toString() ?? '—',
                                        ),
                                        _TablaCellMain(
                                          _formatearMoneda(
                                            item['totalProforma'] ?? 0.0,
                                          ),
                                          isMoneda: true,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 6,
                                          ),
                                          child: Center(
                                            child: ElevatedButton(
                                              onPressed:
                                                  () => _generarPDF([
                                                    item,
                                                  ], unoSolo: true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF4682B4,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: const Size(0, 28),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.picture_as_pdf,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaHeaderMain extends StatelessWidget {
  final String text;
  const _TablaHeaderMain(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TablaCellMain extends StatelessWidget {
  final String? text;
  final bool isMoneda;

  const _TablaCellMain(this.text, {this.isMoneda = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text ?? '—',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isMoneda ? FontWeight.bold : FontWeight.normal,
          color: isMoneda ? Colors.green.shade700 : const Color(0xFF2C3E50),
        ),
        textAlign: isMoneda ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

// ignore: unused_element
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

// ignore: unused_element
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
