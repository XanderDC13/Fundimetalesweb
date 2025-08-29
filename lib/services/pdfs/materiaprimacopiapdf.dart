import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CopiaMateriaPrimaPDFGenerator {
  static Future<pw.Document> generatePDF({
    required String numero,
    required String cliente,
    required DateTime fecha,
    required List<Map<String, String>> items,
  }) async {
    final pdf = pw.Document();

    // Cargar logo
    pw.ImageProvider? logoProvider;
    try {
      final logoBytes = await rootBundle.load('lib/assets/logoletters.png');
      logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Error al cargar logo: $e');
    }

    // Calcular total general
    double totalGeneral = 0.0;
    for (var item in items) {
      totalGeneral += double.tryParse(item['total'] ?? '0') ?? 0.0;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header
              _buildHeader(logoProvider, numero, fecha),
              pw.SizedBox(height: 8),
              _buildClienteInfo(cliente),
              pw.SizedBox(height: 8),
              _buildLeyenda(),
              pw.SizedBox(height: 5),
              _buildItemsTable(items, totalGeneral),
              pw.SizedBox(height: 50),
              pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 1,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'FIRMA DEL CLIENTE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
    pw.ImageProvider? logoProvider,
    String numero,
    DateTime fecha,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        children: [
          // Logo - más pequeño
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              height: 45, // Reducido aún más
              alignment: pw.Alignment.centerLeft,
              child:
                  logoProvider != null
                      ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                      : pw.Container(
                        width: 45,
                        height: 35,
                        color: PdfColor.fromHex('#1f4e79'),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'FN',
                          style: pw.TextStyle(
                            fontSize: 14, // Reducido más
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
            ),
          ),

          // Información de la empresa - más compacta
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'FUNDIMETALES DEL NORTE',
                    style: pw.TextStyle(
                      fontSize: 11, // Reducido más
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'JOSE ALIRIO LOPEZ MARTINEZ',
                    style: pw.TextStyle(
                      fontSize: 8, // Reducido más
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Compra y Venta de Materia Prima',
                    style: pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Direc.: Brasil y Panamá - Telf.: 2962017 - Tulcán - Ecuador',
                    style: pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Información del documento - más compacta
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: pw.EdgeInsets.all(4), // Reducido más
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          numero,
                          style: pw.TextStyle(
                            fontSize: 6, // Reducido más
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'FECHA: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                          style: pw.TextStyle(
                            fontSize: 5,
                          ), // Reducido más y en una línea
                        ),
                      ],
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

  static pw.Widget _buildClienteInfo(String cliente) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(5), // Reducido más
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 1),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'CLIENTE: ',
            style: pw.TextStyle(
              fontSize: 8, // Reducido más
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            cliente,
            style: pw.TextStyle(fontSize: 8), // Reducido más
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLeyenda() {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 2), // Reducido más
      child: pw.Center(
        child: pw.Text(
          'DETALLE DE PROFORMA FUNDICIÓN',
          style: pw.TextStyle(
            fontSize: 9, // Reducido más
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1f4e79'),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    List<Map<String, String>> items,
    double totalGeneral,
  ) {
    return pw.Container(
      // Cambiado de pw.Expanded a pw.Container
      width: double.infinity,
      child: pw.Column(
        children: [
          // Header de la tabla
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1f4e79')),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(4), // Reducido más
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(
                          color: PdfColors.white,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'DESCRIPCIÓN',
                        style: pw.TextStyle(
                          fontSize: 7, // Reducido más
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(6), // Reducido
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(
                          color: PdfColors.white,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'KILOS',
                        style: pw.TextStyle(
                          fontSize: 7, // Reducido más
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(6), // Reducido
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(
                          color: PdfColors.white,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'PRECIO',
                        style: pw.TextStyle(
                          fontSize: 9, // Reducido
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(6), // Reducido
                    child: pw.Center(
                      child: pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(
                          fontSize: 9, // Reducido
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filas de items
          ...items.map(
            (item) => pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(6), // Reducido
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Text(
                        item['descripcion'] ?? '',
                        style: pw.TextStyle(fontSize: 8), // Reducido
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(6), // Reducido
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          item['kilos'] ?? '',
                          style: pw.TextStyle(fontSize: 8), // Reducido
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(6), // Reducido
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '\$${item['precio'] ?? ''}',
                          style: pw.TextStyle(fontSize: 8), // Reducido
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(6), // Reducido
                      child: pw.Center(
                        child: pw.Text(
                          '\$${item['total'] ?? ''}',
                          style: pw.TextStyle(fontSize: 8), // Reducido
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fila del total general
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey, width: 1),
              ),
              color: PdfColor.fromHex('#f0f0f0'),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(8), // Reducido
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.5),
                      ),
                    ),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'TOTAL GENERAL:',
                        style: pw.TextStyle(
                          fontSize: 10, // Reducido
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(8), // Reducido
                    child: pw.Center(
                      child: pw.Text(
                        '\$${totalGeneral.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 10, // Reducido
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1f4e79'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showPreview({
    required String numero,
    required String cliente,
    required DateTime fecha,
    required List<Map<String, String>> items,
  }) async {
    final pdf = await generatePDF(
      numero: numero,
      cliente: cliente,
      fecha: fecha,
      items: items,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}