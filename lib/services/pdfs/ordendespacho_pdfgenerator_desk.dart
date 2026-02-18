import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class OrdenDespachoPDFGenerator {
  static Future<pw.Document> generatePDF({
    required String numeroOrdenDespacho,
    required String cliente,
    required String ciRuc,
    required String email,
    required String telefono,
    required String direccion,
    required String ciudad,
    required List<Map<String, String>> items,
  }) async {
    final pdf = pw.Document();

    // Cargar logo del header
    pw.ImageProvider? logoProvider;
    try {
      final logoBytes = await rootBundle.load('lib/assets/logoletters.png');
      logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Error al cargar logo: $e');
    }

    // Cargar logo de fondo
    pw.ImageProvider? backgroundLogoProvider;
    try {
      final logoBytes = await rootBundle.load('lib/assets/LOGOREDESFTN.png');
      backgroundLogoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Error al cargar logo de fondo: $e');
    }

    // Dividir items en bloques de 16
    const itemsPorPagina = 16;
    final totalPaginas = (items.length / itemsPorPagina).ceil();

    for (int pagina = 0; pagina < totalPaginas; pagina++) {
      final inicio = pagina * itemsPorPagina;
      final fin =
          (inicio + itemsPorPagina > items.length)
              ? items.length
              : inicio + itemsPorPagina;
      final itemsPagina = items.sublist(inicio, fin);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Row(
              children: [
                // Primera orden (izquierda)
                pw.Expanded(
                  child: pw.Container(
                    margin: pw.EdgeInsets.only(right: 5),
                    child: pw.Column(
                      children: [
                        _buildHeader(logoProvider, numeroOrdenDespacho),
                        pw.SizedBox(height: 12),
                        _buildClienteInfo(
                          cliente,
                          ciRuc,
                          email,
                          telefono,
                          ciudad,
                          direccion,
                        ),
                        pw.SizedBox(height: 12),
                        _buildLeyenda(),
                        pw.SizedBox(height: 8),
                        pw.Expanded(
                          child: pw.Stack(
                            children: [
                              // Solo el logo de fondo en el Stack
                              if (backgroundLogoProvider != null)
                                pw.Positioned.fill(
                                  child: pw.Opacity(
                                    opacity: 0.20,
                                    child: pw.Center(
                                      child: pw.Container(
                                        width: 200,
                                        height: 200,
                                        child: pw.Image(
                                          backgroundLogoProvider,
                                          fit: pw.BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // La tabla y footer en Column, por encima del logo
                              pw.Column(
                                children: [
                                  pw.Expanded(
                                    child: _buildItemsTable(itemsPagina),
                                  ),
                                  pw.SizedBox(height: 8),
                                  _buildFooter(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Línea divisoria vertical
                pw.Container(
                  width: 1,
                  color: PdfColors.grey,
                  margin: pw.EdgeInsets.symmetric(horizontal: 5),
                ),

                // Segunda orden (derecha) - IDÉNTICA
                pw.Expanded(
                  child: pw.Container(
                    margin: pw.EdgeInsets.only(left: 5),
                    child: pw.Column(
                      children: [
                        _buildHeader(logoProvider, numeroOrdenDespacho),
                        pw.SizedBox(height: 12),
                        _buildClienteInfo(
                          cliente,
                          ciRuc,
                          email,
                          telefono,
                          ciudad,
                          direccion,
                        ),
                        pw.SizedBox(height: 12),
                        _buildLeyenda(),
                        pw.SizedBox(height: 8),
                        pw.Expanded(
                          child: pw.Stack(
                            children: [
                              // Solo el logo de fondo en el Stack
                              if (backgroundLogoProvider != null)
                                pw.Positioned.fill(
                                  child: pw.Opacity(
                                    opacity: 0.20,
                                    child: pw.Center(
                                      child: pw.Container(
                                        width: 200,
                                        height: 200,
                                        child: pw.Image(
                                          backgroundLogoProvider,
                                          fit: pw.BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // La tabla y footer en Column, por encima del logo
                              pw.Column(
                                children: [
                                  pw.Expanded(
                                    child: _buildItemsTable(itemsPagina),
                                  ),
                                  pw.SizedBox(height: 8),
                                  _buildFooter(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  static pw.Widget _buildHeader(
    pw.ImageProvider? logoProvider,
    String numeroOrdenDespacho,
  ) {
    return pw.Container(
      width: double.infinity,
      height: 70,
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child:
                  logoProvider != null
                      ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                      : pw.Container(
                        width: 60,
                        height: 40,
                        color: PdfColor.fromHex('#1f4e79'),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'FN',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
            ),
          ),

          // CENTRO: INFORMACIÓN DE LA EMPRESA
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'FUNDIMETALES DEL NORTE',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'JOSE ALIRIO LOPEZ MARTINEZ',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Fábrica de Campanas o Tambores para frenos de Automotores',
                    style: pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'en todas las marcas y modelos - Fabricamos toda clase de adaptaciones',
                    style: pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Direc.: Brasil y Panamá - Telf.: 0979230282 - Tulcán - Ecuador',
                    style: pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // DERECHA: RUC, ORDEN, NÚMERO Y FECHA (20% del ancho)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'RUC. 0401563812001',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'ORDEN DE DESPACHO',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    numeroOrdenDespacho,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _buildFechaBox('D', '${DateTime.now().day}', 14),
                      pw.SizedBox(width: 2),
                      _buildFechaBox('M', '${DateTime.now().month}', 14),
                      pw.SizedBox(width: 2),
                      _buildFechaBox('A', '${DateTime.now().year}', 18),
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
          style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
        ),
        pw.Container(
          width: width,
          height: 9,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.1),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClienteInfo(
    String cliente,
    String ciRuc,
    String email,
    String telefono,
    String ciudad,
    String direccion,
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
          // Segunda fila: EMAIL y TELEFONO
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
                          'TELEFONO: ',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            telefono,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tercera fila: CIUDAD y DIRECCION
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
                          'CIUDAD: ',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            ciudad,
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
                    padding: pw.EdgeInsets.all(4),
                    // Sin height fijo
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DIRECCION: ',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            direccion,
                            style: pw.TextStyle(fontSize: 8),
                            // Sin maxLines
                          ),
                        ),
                      ],
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
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    // 👈 Agrega "static"
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Izquierda
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'SOFTWARE ELABORADO POR FUNDIMETALES DEL NORTE',
                style: pw.TextStyle(
                  fontSize: 6,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'sistemas@fundimetalesdelnorte.com',
                style: pw.TextStyle(fontSize: 6),
              ),
            ],
          ),
          // Derecha
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'LENIN ANDRES ONTANEDA YAPUD',
                style: pw.TextStyle(
                  fontSize: 6,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'ADMINISTRACIÓN - 0984202144',
                style: pw.TextStyle(fontSize: 6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> showPreview({
    required String numeroOrdenDespacho,
    required String cliente,
    required String ciRuc,
    required String email,
    required String telefono,
    required String direccion,
    required String ciudad,
    required List<Map<String, String>> items,
  }) async {
    final pdf = await generatePDF(
      numeroOrdenDespacho: numeroOrdenDespacho,
      cliente: cliente,
      ciRuc: ciRuc,
      email: email,
      telefono: telefono,
      direccion: direccion,
      ciudad: ciudad,
      items: items,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
