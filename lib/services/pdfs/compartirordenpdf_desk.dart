import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class OrdenPDFCompartir {
  static Future<pw.Document> generatePDF({
    required String numeroOrden,
    required String cliente,
    required String ciRuc,
    required String email,
    required String direccion,
    required String ciudad,
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Row(
            children: [
              // Orden
              pw.Expanded(
                child: pw.Container(
                  margin: pw.EdgeInsets.only(left: 5),
                  child: pw.Column(
                    children: [
                      _buildHeader(logoProvider, numeroOrden),
                      pw.SizedBox(height: 12),
                      _buildClienteInfo(
                        cliente,
                        ciRuc,
                        email,
                        direccion,
                        ciudad,
                      ),
                      pw.SizedBox(height: 12),
                      _buildLeyenda(),
                      pw.SizedBox(height: 8),
                      _buildItemsTable(items),
                      pw.Spacer(),
                    ],
                  ),
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
    String numeroOrden,
  ) {
    return pw.Container(
      width: double.infinity,
      height: 90, // Alto fijo
      padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: pw.Row(
        children: [
          // IZQUIERDA: LOGO (25% del ancho)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child:
                  logoProvider != null
                      ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                      : pw.Container(
                        width: 80,
                        height: 50,
                        color: PdfColor.fromHex('#1f4e79'),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'FN',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
            ),
          ),

          // CENTRO: INFORMACIÓN DE LA EMPRESA (50% del ancho)
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment:
                    pw.CrossAxisAlignment.center, // TODO CENTRADO
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'FUNDIMETALES DEL NORTE',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'JOSE ALIRIO LOPEZ MARTINEZ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Fábrica de Campanas o Tambores para frenos de Automotores en todas las marcas y modelos',
                    style: pw.TextStyle(fontSize: 6.5),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Fabricamos toda clase de adaptaciones',
                    style: pw.TextStyle(fontSize: 6.5),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Direc.: Brasil y Panamá Telf.: 0979230282 - Tulcán - Ecuador',
                    style: pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // DERECHA: RUC, PROFORMA, NÚMERO Y FECHA (25% del ancho)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  // RUC
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: pw.Text(
                      'RUC. 0401563812001',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),

                  pw.SizedBox(height: 3),

                  // PROFORMA
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: pw.Text(
                      'ORDEN DE DESPACHO',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),

                  pw.SizedBox(height: 2),

                  // NÚMERO
                  pw.Text(
                    numeroOrden,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 3),

                  // FECHA
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _buildFechaBox('D', '${DateTime.now().day}', 18),
                      pw.SizedBox(width: 2),
                      _buildFechaBox('M', '${DateTime.now().month}', 18),
                      pw.SizedBox(width: 2),
                      _buildFechaBox('A', '${DateTime.now().year}', 22),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFechaBox(String label, String value, double width) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
        pw.Container(
          width: width,
          height: 10,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.1),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClienteInfo(
    String cliente,
    String ciRuc,
    String email,
    String direccion,
    String ciudad,
  ) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 0.3),
      ),
      child: pw.Column(
        children: [
          // Primera fila: CLIENTE y C.I/RUC
          pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'CLIENTE: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          cliente,
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'C.I/RUC: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(ciRuc, style: pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Segunda fila: EMAIL y DIRECCION
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          'EMAIL: ',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            email,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(6),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          'DIRECCION: ',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            direccion,
                            style: pw.TextStyle(fontSize: 9),
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tercera fila: CIUDAD
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
              ),
            ),
            child: pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(6),
              child: pw.Row(
                children: [
                  pw.Text(
                    'CIUDAD: ',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(ciudad, style: pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLeyenda() {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Center(
        child: pw.Text(
          'DESPACHAMOS A USTEDES LOS SIGUIENTES ARTICULOS',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<Map<String, String>> items) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 0.3),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1f4e79')),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'REF.',
                        style: pw.TextStyle(
                          fontSize: 10,
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
                    padding: pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'CANT.',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Center(
                      child: pw.Text(
                        'DESCRIPCION DEL ARTICULO',
                        style: pw.TextStyle(
                          fontSize: 10,
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
          // Items
          ...items.map(
            (item) => pw.Container(
              height: 20,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(2),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          item['ref'] ?? '',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(2),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          item['cantidad'] ?? '',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(2),
                      child: pw.Text(
                        item['descripcion'] ?? '',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Filas vacías para completar la tabla
          for (int i = items.length; i < 28; i++)
            pw.Container(
              height: 20,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(flex: 4, child: pw.Container()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> showPreview({
    required String numeroOrden,
    required String cliente,
    required String ciRuc,
    required String email,
    required String direccion,
    required String ciudad,
    required List<Map<String, String>> items,
  }) async {
    final pdf = await generatePDF(
      numeroOrden: numeroOrden,
      cliente: cliente,
      ciRuc: ciRuc,
      email: email,
      direccion: direccion,
      ciudad: ciudad,
      items: items,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> shareDocument({
    required String numeroOrden,
    required String cliente,
    required String ciRuc,
    required String email,
    required String direccion,
    required String ciudad,
    required List<Map<String, String>> items,
  }) async {
    final pdf = await generatePDF(
      numeroOrden: numeroOrden,
      cliente: cliente,
      ciRuc: ciRuc,
      email: email,
      direccion: direccion,
      ciudad: ciudad,
      items: items,
    );

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'orden_despacho_$numeroOrden.pdf',
    );
  }
}
